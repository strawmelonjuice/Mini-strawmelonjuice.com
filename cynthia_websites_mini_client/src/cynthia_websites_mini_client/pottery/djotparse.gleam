//// Djot is parsed using jot, then converted to lustre elements using jotkey/jot_to_lustre's logic, slightly modified to fit Cynthia's needs.

import cynthia_websites_mini_client/utils
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import jot.{
  type Container, type Destination, type Document, type Inline, Code, Codeblock,
  Emphasis, Heading, Image, Linebreak, Link, Paragraph, Reference, Strong, Text,
  Url,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn entry_to_conversion(djot: String) -> List(Element(msg)) {
  let preprocessed = preprocess_djot_extensions(djot)
  let parsed = jot.parse(preprocessed)
  document_to_lustre(parsed)
}

pub fn preprocess_djot_extensions(djot: String) -> String {
  let normalized =
    djot
    |> string.replace("\r\n", "\n")
    // Normalize line endings
    |> string.replace("\r", "\n")
    // Handle old Mac line endings
    |> string.replace("\\!", "!")
    // Convert escaped exclamation marks
    |> string.trim()
  // Remove leading/trailing whitespace

  // Process heading attributes first to ensure IDs are attached correctly
  let with_heading_attrs = preprocess_heading_attributes(normalized)

  // Fix multiline images
  let with_fixed_images = preprocess_multiline_images(with_heading_attrs)

  let with_autolinks = with_fixed_images |> preprocess_autolinks

  let with_strikethrough = with_autolinks |> preprocess_strikethrough

  let with_tables = with_strikethrough |> preprocess_tables
  let with_blockquotes = with_tables |> preprocess_blockquotes

  let with_task_lists = with_blockquotes |> preprocess_task_lists

  let with_definition_lists = with_task_lists |> preprocess_definition_lists

  with_definition_lists
}

fn document_to_lustre(document: Document) -> List(Element(msg)) {
  let elements = containers_to_lustre(document.content, document.references, [])

  // Add footnotes section if any footnotes exist
  let elements_with_footnotes = case dict.size(document.footnotes) > 0 {
    True -> {
      let footnotes_section =
        create_footnotes_section(document.footnotes, document.references)
      list.append(elements, [footnotes_section])
    }
    False -> elements
  }

  list.reverse(elements_with_footnotes)
}

fn containers_to_lustre(
  containers containers: List(Container),
  refs refs: Dict(String, String),
  elements elements: List(Element(msg)),
) -> List(Element(msg)) {
  case containers {
    [] -> elements
    [container, ..rest] -> {
      let elements = container_to_lustre(elements, container, refs)
      containers_to_lustre(rest, refs, elements)
    }
  }
}

fn container_to_lustre(
  elements: List(Element(msg)),
  container: Container,
  refs: Dict(String, String),
) {
  let element = case container {
    Paragraph(attrs, inlines) -> {
      // Check if this paragraph is an ordered list
      case is_ordered_list_paragraph(inlines) {
        True -> {
          // Extract the list items from the text
          let items = extract_ordered_list_items(inlines)

          // Split the inlines to separate text from other elements like images
          // (We don't need text_content anymore since we extract items directly)

          let non_text_inlines =
            list.filter(inlines, fn(inline) {
              case inline {
                Text(_) -> False
                _ -> True
              }
            })

          // Render as an ordered list
          html.ol(
            attributes_to_lustre(attrs, [attribute.class("list-decimal mb-4")]),
            list.map(items, fn(item) {
              let #(num, content) = item

              // Add non-text inlines only to the last list item
              let is_last_item = num == list.length(items)
              let item_content = case
                is_last_item,
                list.length(non_text_inlines) > 0
              {
                True, True -> {
                  // For the last item, include any non-text inlines (images, links, etc.)
                  inlines_to_lustre(
                    [],
                    [Text(content), ..non_text_inlines],
                    refs,
                  )
                }
                _, _ -> {
                  // For other items, just use the text
                  [html.text(content)]
                }
              }

              html.li([], item_content)
            }),
          )
        }
        False -> {
          // Regular paragraph
          let in_a_list = case refs |> dict.get("am I in a list?") {
            Ok(..) -> True
            _ -> False
          }

          html.p(
            attributes_to_lustre(attrs, [
              case in_a_list {
                False -> attribute.class("mb-2")
                True -> attribute.class("whitespace-nowrap")
              },
            ]),
            inlines_to_lustre([], inlines, refs),
          )
        }
      }
    }
    Heading(attrs, level, inlines) -> {
      // Clean heading text to remove {#id} markup
      let clean_inlines = clean_heading_text(inlines)

      case level {
        1 ->
          html.h1(
            attributes_to_lustre(attrs, [
              attribute.class("text-4xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], clean_inlines, refs),
          )
        2 ->
          html.h2(
            attributes_to_lustre(attrs, [
              attribute.class("text-3xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], clean_inlines, refs),
          )
        3 ->
          html.h3(
            attributes_to_lustre(attrs, [
              attribute.class("text-2xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], clean_inlines, refs),
          )
        4 ->
          html.h4(
            attributes_to_lustre(attrs, [
              attribute.class("text-xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], clean_inlines, refs),
          )
        5 ->
          html.h5(
            attributes_to_lustre(attrs, [
              attribute.class("text-lg font-bold text-accent"),
            ]),
            inlines_to_lustre([], clean_inlines, refs),
          )
        _ ->
          html.h6(
            attributes_to_lustre(attrs, [
              attribute.class("font-bold text-accent"),
            ]),
            inlines_to_lustre([], clean_inlines, refs),
          )
      }
    }
    Codeblock(attrs, language, content) -> {
      html.pre(
        attributes_to_lustre(attrs, [
          attribute.class(
            "bg-neutral text-neutral-content pl-4 block ml-2 mr-2 overflow-x-auto break-none whitespace-pre-wrap font-mono border-dotted border-2 border-neutral-content rounded-lg",
          ),
        ]),
        [
          html.code(
            case language {
              Some(lang) -> [
                attribute.class("language-" <> lang),
                attribute.attribute("data-language", lang),
              ]
              None -> []
            }
              |> list.append([
                attribute.class(
                  "bg-neutral text-neutral-content p-1 rounded-lg",
                ),
              ]),
            [
              case language {
                Some(lang) ->
                  html.div(
                    [
                      attribute.class(
                        "text-xs text-neutral-content opacity-70 mb-2",
                      ),
                    ],
                    [html.text(string.uppercase(lang))],
                  )
                None -> element.none()
              },
              html.text(content),
            ]
              |> list.filter(fn(el) { el != element.none() }),
          ),
        ],
      )
    }
    jot.BulletList(layout:, style: _, items:) -> {
      html.ul(
        [
          attribute.class(
            "list-disc"
            <> {
              " leading-"
              <> case layout {
                jot.Loose -> "loose"
                jot.Tight -> "tight"
              }
            },
          ),
        ],
        list.map(items, fn(item) {
          html.li(
            [],
            containers_to_lustre(
              containers: item,
              refs: refs |> dict.insert("am I in a list?", "yes."),
              elements: [],
            ),
          )
        }),
      )
    }
    // Raw blocks are perfect for our preprocessed HTML
    jot.RawBlock(content:) ->
      element.unsafe_raw_html(
        "div",
        "div",
        [attribute.class("djot-processed-content")],
        content,
      )
    jot.ThematicBreak ->
      html.hr([
        attribute.class("w-48 h-1 mx-auto my-4 border-0 rounded-sm md:my-10"),
      ])
  }
  [element, ..elements]
}

fn inlines_to_lustre(
  elements: List(Element(msg)),
  inlines: List(Inline),
  refs: Dict(String, String),
) -> List(Element(msg)) {
  case inlines {
    [] -> list.reverse(elements)
    [inline, ..rest] -> {
      let new_elements = inline_to_lustre([], inline, refs)
      inlines_to_lustre(list.append(new_elements, elements), rest, refs)
    }
  }
}

fn inline_to_lustre(
  elements: List(Element(msg)),
  inline: Inline,
  refs: Dict(String, String),
) {
  case inline {
    Linebreak -> [html.br([])]
    Text(text) -> [html.text(text)]
    Strong(inlines) -> {
      [
        html.strong(
          [attribute.class("font-bold")],
          inlines_to_lustre(elements, inlines, refs),
        ),
      ]
    }
    Emphasis(inlines) -> {
      [
        html.em(
          [attribute.class("italic")],
          inlines_to_lustre(elements, inlines, refs),
        ),
      ]
    }
    Link(text, destination) -> {
      [
        case destination {
          Url(url) -> {
            html.a(
              [
                attribute.class("text-info underline"),
                attribute.href({
                  case
                    string.starts_with(url, "/")
                    && !string.starts_with(url, utils.phone_home_url() <> "#")
                  {
                    True -> utils.phone_home_url() <> "#" <> url
                    False -> url
                  }
                }),
              ],
              inlines_to_lustre(elements, text, refs),
            )
          }
          Reference(ref_id) -> {
            case dict.get(refs, ref_id) {
              Ok(url) -> {
                html.a(
                  [
                    attribute.class("text-info underline"),
                    attribute.href({
                      case
                        string.starts_with(url, "/")
                        && !string.starts_with(
                          url,
                          utils.phone_home_url() <> "#",
                        )
                      {
                        True -> utils.phone_home_url() <> "#" <> url
                        False -> url
                      }
                    }),
                  ],
                  inlines_to_lustre(elements, text, refs),
                )
              }
              Error(_) -> {
                html.span([attribute.class("text-error")], [
                  html.text("[Reference not found: " <> ref_id <> "]"),
                ])
              }
            }
          }
        },
      ]
    }
    Image(text, destination) -> {
      [
        html.img([
          attribute.src(destination_attribute(destination, refs)),
          attribute.alt(take_inline_text(text, "")),
        ]),
      ]
    }
    Code(content) -> {
      [
        html.code(
          [attribute.class("bg-neutral text-neutral-content p-1 rounded-lg")],
          [html.text(content)],
        ),
      ]
    }
    jot.Footnote(reference: reference) -> {
      [
        html.a(
          [
            attribute.href("#fn:" <> reference),
            attribute.id("fnref:" <> reference),
            attribute.class("text-info text-xs align-super"),
            attribute.attribute("role", "doc-noteref"),
          ],
          [html.text("[" <> reference <> "]")],
        ),
      ]
    }
    jot.MathDisplay(content: content) -> {
      [
        element.unsafe_raw_html(
          "div",
          "div",
          [attribute.class("math-display my-4 text-center overflow-x-auto")],
          "\\[" <> content <> "\\]",
        ),
      ]
    }
    jot.MathInline(content: content) -> {
      [
        element.unsafe_raw_html(
          "span",
          "span",
          [attribute.class("math-inline")],
          "\\(" <> content <> "\\)",
        ),
      ]
    }
    jot.NonBreakingSpace -> [html.text(" ")]
  }
}

fn destination_attribute(destination: Destination, refs: Dict(String, String)) {
  case destination {
    Url(url) -> url
    Reference(id) ->
      case dict.get(refs, id) {
        Ok(url) -> url
        Error(Nil) -> ""
      }
  }
}

fn take_inline_text(inlines: List(Inline), acc: String) -> String {
  case inlines {
    [] -> acc
    [first, ..rest] ->
      case first {
        Text(text) | Code(text) -> take_inline_text(rest, acc <> text)
        Strong(inlines) | Emphasis(inlines) ->
          take_inline_text(list.append(inlines, rest), acc)
        Link(nested, _) | Image(nested, _) -> {
          let acc = take_inline_text(nested, acc)
          take_inline_text(rest, acc)
        }
        Linebreak -> {
          take_inline_text(rest, acc)
        }
        jot.Footnote(reference: reference) -> "[" <> reference <> "]"
        jot.MathDisplay(content: content) -> content
        jot.MathInline(content: content) -> content
        jot.NonBreakingSpace ->
          // Non-breaking space.
          " "
      }
  }
}

fn attributes_to_lustre(attributes: Dict(String, String), lustre_attributes) {
  attributes
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
  |> list.fold(lustre_attributes, fn(lustre_attributes, pair) {
    [attribute.attribute(pair.0, pair.1), ..lustre_attributes]
  })
}

fn create_footnotes_section(
  footnotes: Dict(String, List(Container)),
  refs: Dict(String, String),
) -> Element(msg) {
  case dict.size(footnotes) > 0 {
    True -> {
      html.section(
        [attribute.class("footnotes mt-8 pt-4 border-t border-neutral-content")],
        [
          html.h2([attribute.class("text-xl font-bold text-accent mb-4")], [
            html.text("Footnotes"),
          ]),
          html.ol(
            [attribute.class("list-decimal list-inside space-y-2")],
            footnotes
              |> dict.to_list
              |> list.map(fn(footnote) {
                let #(id, containers) = footnote
                html.li(
                  [attribute.id("fn:" <> id), attribute.class("text-sm")],
                  list.append(containers_to_lustre(containers, refs, []), [
                    html.a(
                      [
                        attribute.href("#fnref:" <> id),
                        attribute.class("text-info ml-2"),
                        attribute.attribute("role", "doc-backlink"),
                      ],
                      [html.text("↩")],
                    ),
                  ]),
                )
              }),
          ),
        ],
      )
    }
    False -> element.none()
  }
}

fn preprocess_tables(djot: String) -> String {
  let lines = string.split(djot, "\n")
  process_table_lines(lines, False, [])
  |> string.join("\n")
}

fn process_table_lines(
  lines: List(String),
  in_table: Bool,
  table_buffer: List(String),
) -> List(String) {
  case lines {
    [] ->
      case in_table {
        True -> [convert_table_to_raw(table_buffer)]
        False -> []
      }

    [line, ..rest] -> {
      let is_table_line = string.contains(line, "|") && string.trim(line) != ""
      let is_separator =
        string.contains(line, "|") && string.contains(line, "-")

      case in_table, is_table_line || is_separator {
        True, True -> process_table_lines(rest, True, [line, ..table_buffer])

        True, False -> [
          convert_table_to_raw(list.reverse(table_buffer)),
          line,
          ..process_table_lines(rest, False, [])
        ]

        False, True -> process_table_lines(rest, True, [line])

        False, False -> [line, ..process_table_lines(rest, False, [])]
      }
    }
  }
}

fn convert_table_to_raw(lines: List(String)) -> String {
  case lines {
    [header, separator, ..rows] -> {
      case string.contains(separator, "|") && string.contains(separator, "-") {
        True -> {
          let header_cells =
            header
            |> string.split("|")
            |> list.map(string.trim)
            |> list.filter(fn(cell) { cell != "" })

          let data_rows =
            rows
            |> list.map(fn(row) {
              row
              |> string.split("|")
              |> list.map(string.trim)
              |> list.filter(fn(cell) { cell != "" })
            })
            |> list.filter(fn(row) { list.length(row) > 0 })

          let header_html =
            header_cells
            |> list.map(fn(cell) {
              "<th class=\"px-4 py-2 text-left font-bold\">" <> cell <> "</th>"
            })
            |> string.join("")
          let rows_html =
            data_rows
            |> list.map(fn(row) {
              let cells_html =
                row
                |> list.map(fn(cell) {
                  "<td class=\"px-4 py-2 border-t border-neutral-content\">"
                  <> cell
                  <> "</td>"
                })
                |> string.join("")
              "<tr class=\"hover:bg-base-200\">" <> cells_html <> "</tr>"
            })
            |> string.join("")

          let table_html =
            "<table class=\"table table-zebra w-full my-4 border border-neutral-content\">"
            <> "<thead class=\"bg-neutral text-neutral-content\">"
            <> "<tr>"
            <> header_html
            <> "</tr></thead>"
            <> "<tbody>"
            <> rows_html
            <> "</tbody></table>"

          "```=html\n" <> table_html <> "\n```"
        }
        False -> string.join(lines, "\n")
      }
    }
    _ -> string.join(lines, "\n")
  }
}

pub fn preprocess_blockquotes(djot: String) -> String {
  // Process blockquotes as groups, not individual lines
  let lines = string.split(djot, "\n")
  process_blockquote_lines(lines, [], [], False)
  |> string.join("\n")
}

fn process_blockquote_lines(
  lines: List(String),
  processed: List(String),
  blockquote_buffer: List(String),
  in_blockquote: Bool,
) -> List(String) {
  case lines {
    [] -> {
      // If we have a blockquote buffer at the end, process it
      case in_blockquote {
        True -> {
          let blockquote =
            convert_blockquote_to_raw(list.reverse(blockquote_buffer))
          list.reverse([blockquote, ..processed])
        }
        False -> list.reverse(processed)
      }
    }

    [line, ..rest] -> {
      let trimmed = string.trim(line)
      let is_blockquote_line = string.starts_with(trimmed, "> ")

      case in_blockquote, is_blockquote_line {
        // Continue collecting blockquote lines
        True, True -> {
          let content = string.drop_start(trimmed, 2) |> string.trim()
          process_blockquote_lines(
            rest,
            processed,
            [content, ..blockquote_buffer],
            True,
          )
        }

        // End of blockquote
        True, False -> {
          let blockquote =
            convert_blockquote_to_raw(list.reverse(blockquote_buffer))
          process_blockquote_lines(rest, [blockquote, ..processed], [], False)
        }

        // Start of blockquote
        False, True -> {
          let content = string.drop_start(trimmed, 2) |> string.trim()
          process_blockquote_lines(rest, processed, [content], True)
        }

        // Regular line, not in blockquote
        False, False -> {
          process_blockquote_lines(rest, [line, ..processed], [], False)
        }
      }
    }
  }
}

fn convert_blockquote_to_raw(lines: List(String)) -> String {
  let content =
    lines
    |> list.map(fn(line) {
      case line {
        // Any line without content should be an empty line broken.
        "" -> "\n"
        " " -> "\n"
        "\\" -> ""
        _ -> line
      }
    })
    |> string.join("\n")

  html.blockquote(
    [
      attribute.class(
        "border-l-4 border-accent border-dotted pl-4 bg-secondary bg-opacity-10 mb-4 mt-4",
      ),
    ],
    [html.pre([], [element.text(content)])],
  )
  |> element_to_raw
}

/// Converts a Lustre element to a raw block Djot representation.
fn element_to_raw(elm: element.Element(a)) {
  "\n```=html\n" <> { elm |> element.to_string } <> "\n```\n"
}

fn preprocess_task_lists(djot: String) -> String {
  djot
  |> string.split("\n")
  |> list.map(fn(line) {
    let trimmed = string.trim(line)
    case string.starts_with(trimmed, "- [ ] ") {
      True -> {
        let content = string.drop_start(trimmed, 6)
        {
          html.div([attribute.class("flex items-center mb-2")], [
            html.input([
              attribute.type_("checkbox"),
              attribute.disabled(True),
              attribute.class("mr-2 accent-primary"),
            ]),
            element.text(content),
          ])
        }
        |> element_to_raw
      }
      False ->
        case
          string.starts_with(trimmed, "- [x] ")
          || string.starts_with(trimmed, "- [X] ")
        {
          True -> {
            let content = string.drop_start(trimmed, 6)
            "```=html\n<div class=\"flex items-center mb-2\"><input type=\"checkbox\" checked disabled class=\"mr-2 accent-primary\">"
            <> content
            <> "</div>\n```"
          }
          False -> line
        }
    }
  })
  |> string.join("\n")
}

fn preprocess_definition_lists(djot: String) -> String {
  let lines = string.split(djot, "\n")
  process_definition_list_lines(lines, False, [], "")
  |> string.join("\n")
}

fn process_definition_list_lines(
  lines: List(String),
  in_list: Bool,
  list_buffer: List(String),
  current_term: String,
) -> List(String) {
  case lines {
    [] ->
      case in_list {
        True -> [convert_definition_list_to_raw(list_buffer)]
        False -> []
      }

    [line, ..rest] -> {
      let trimmed = string.trim(line)
      // More restrictive definition list detection:
      // Only consider it a term if the NEXT line starts with ":"
      let is_definition = string.starts_with(trimmed, ":")
      let next_line_is_definition = case rest {
        [next, ..] -> string.starts_with(string.trim(next), ":")
        [] -> False
      }
      let is_term = !is_definition && trimmed != "" && next_line_is_definition

      case in_list, is_term || is_definition {
        True, True ->
          case is_definition {
            True -> {
              let definition = string.drop_start(trimmed, 1) |> string.trim()
              let entry = current_term <> "|" <> definition
              process_definition_list_lines(
                rest,
                True,
                [entry, ..list_buffer],
                "",
              )
            }
            False -> {
              // is_term is True
              process_definition_list_lines(rest, True, list_buffer, trimmed)
            }
          }

        True, False -> [
          convert_definition_list_to_raw(list.reverse(list_buffer)),
          line,
          ..process_definition_list_lines(rest, False, [], "")
        ]

        False, True ->
          case is_term {
            True -> process_definition_list_lines(rest, True, [], trimmed)
            False -> [
              line,
              ..process_definition_list_lines(rest, False, [], "")
            ]
          }

        False, False -> [
          line,
          ..process_definition_list_lines(rest, False, [], "")
        ]
      }
    }
  }
}

fn convert_definition_list_to_raw(entries: List(String)) -> String {
  case list.length(entries) > 0 {
    True -> {
      let dl_items =
        entries
        |> list.map(fn(entry) {
          case string.split_once(entry, "|") {
            Ok(#(term, definition)) ->
              "<dt class=\"font-bold text-accent mt-4 first:mt-0\">"
              <> term
              <> "</dt>"
              <> "<dd class=\"ml-4 text-base-content/80\">"
              <> definition
              <> "</dd>"
            Error(_) -> ""
          }
        })
        |> string.join("")

      "```=html\n<dl class=\"my-4\">" <> dl_items <> "</dl>\n```"
    }
    False -> ""
  }
}

fn preprocess_strikethrough(djot: String) -> String {
  // Convert ~~text~~ to raw HTML <del>text</del>
  djot
  |> string.replace("~~", "🔗STRIKE🔗")
  // Temporary marker to avoid conflicts
  |> process_strikethrough_markers()
}

fn process_strikethrough_markers(input: String) -> String {
  case string.split_once(input, "🔗STRIKE🔗") {
    Ok(#(before, after)) -> {
      case string.split_once(after, "🔗STRIKE🔗") {
        Ok(#(middle, rest)) ->
          before
          <> "<del class=\"line-through opacity-70\">"
          <> middle
          <> "</del>"
          <> process_strikethrough_markers(rest)
        Error(_) -> before <> "~~" <> after
        // Single marker, restore original
      }
    }
    Error(_) -> input
    // No markers found
  }
}

fn preprocess_autolinks(djot: String) -> String {
  // Convert <url> to [url](url) format for proper Djot parsing
  djot
  |> string.replace("<https://", "🔗AUTOLINK🔗https://")
  |> string.replace("<http://", "🔗AUTOLINK🔗http://")
  |> string.replace("<ftp://", "🔗AUTOLINK🔗ftp://")
  |> string.replace("<mailto:", "🔗AUTOLINK🔗mailto:")
  |> process_autolink_markers()
}

fn process_autolink_markers(input: String) -> String {
  case string.split_once(input, "🔗AUTOLINK🔗") {
    Ok(#(before, after)) -> {
      case string.split_once(after, ">") {
        Ok(#(url, rest)) ->
          before
          <> "["
          <> url
          <> "]("
          <> url
          <> ")"
          <> process_autolink_markers(rest)
        Error(_) -> before <> "<" <> after
        // Restore if no closing >
      }
    }
    Error(_) -> input
    // No markers found
  }
}

// Check if paragraph inlines represent an ordered list
fn is_ordered_list_paragraph(inlines: List(Inline)) -> Bool {
  case inlines {
    [Text(text), ..] -> {
      let lines = string.split(text, "\n")

      // Check if all lines match the ordered list pattern (number. content)
      list.all(lines, fn(line) {
        case string.split_once(line, ". ") {
          Ok(#(num, _)) -> {
            case int.parse(num) {
              Ok(_) -> True
              Error(_) -> False
            }
          }
          Error(_) -> False
        }
      })
      && list.length(lines) > 0
    }
    _ -> False
  }
}

// Extract list items from paragraph text
// Returns a list of tuples with (item number, item text content)
fn extract_ordered_list_items(inlines: List(Inline)) -> List(#(Int, String)) {
  case inlines {
    [Text(text), ..] -> {
      let lines = string.split(text, "\n")

      // Parse each line into a tuple of (number, content)
      list.filter_map(lines, fn(line) {
        case string.split_once(line, ". ") {
          Ok(#(num, content)) -> {
            case int.parse(num) {
              Ok(n) -> Ok(#(n, content))
              Error(_) -> Error(Nil)
            }
          }
          Error(_) -> Error(Nil)
        }
      })
    }
    _ -> []
  }
}

pub fn preprocess_multiline_images(djot: String) -> String {
  string.split(djot, "\n")
  |> process_multiline_image_lines([], "")
  |> string.join("\n")
}

fn process_multiline_image_lines(
  lines: List(String),
  processed: List(String),
  buffer: String,
) -> List(String) {
  case lines {
    [] -> list.reverse(processed)

    [line, ..rest] -> {
      let has_image_start = string.contains(line, "![")
      let has_image_end = string.contains(line, ")")
      let has_incomplete_image = has_image_start && !has_image_end

      case buffer {
        // No buffer yet
        "" -> {
          case has_incomplete_image {
            // Start collecting a multiline image
            True -> process_multiline_image_lines(rest, processed, line)

            // Normal line
            False ->
              process_multiline_image_lines(rest, [line, ..processed], "")
          }
        }

        // Continue collecting an existing multiline image
        _ -> {
          // If we have a buffer, we're in the middle of processing a multiline image
          // We need to combine all lines until we find the closing parenthesis
          case has_image_end {
            // Complete the image and add to processed
            True -> {
              let complete_line = buffer <> " " <> line
              process_multiline_image_lines(
                rest,
                [complete_line, ..processed],
                "",
              )
            }
            // Continue buffering
            False -> {
              process_multiline_image_lines(
                rest,
                processed,
                buffer <> " " <> line,
              )
            }
          }
        }
      }
    }
  }
}

// Process heading attributes like {#id} before headings
pub fn preprocess_heading_attributes(djot: String) -> String {
  let lines = string.split(djot, "\n")
  let processed = process_heading_attribute_lines(lines, [])
  string.join(processed, "\n")
}

fn process_heading_attribute_lines(
  lines: List(String),
  processed: List(String),
) -> List(String) {
  case lines {
    [] -> list.reverse(processed)

    [line, ..rest] -> {
      // Check for attribute pattern {#something} followed by heading
      let is_attribute =
        string.starts_with(string.trim(line), "{#")
        && string.contains(line, "}")

      case is_attribute, rest {
        True, [next, ..next_rest] -> {
          let next_trimmed = string.trim(next)
          // Check if next line is a heading
          case
            string.starts_with(next_trimmed, "# ")
            || string.starts_with(next_trimmed, "## ")
            || string.starts_with(next_trimmed, "### ")
            || string.starts_with(next_trimmed, "#### ")
            || string.starts_with(next_trimmed, "##### ")
            || string.starts_with(next_trimmed, "###### ")
          {
            True -> {
              // Extract ID from {#id}
              case string.split_once(line, "{#") {
                Ok(#(_, with_id)) -> {
                  case string.split_once(with_id, "}") {
                    Ok(#(id, _)) -> {
                      let modified_heading = next <> " {#" <> id <> "}"
                      process_heading_attribute_lines(next_rest, [
                        modified_heading,
                        ..processed
                      ])
                    }
                    Error(_) ->
                      process_heading_attribute_lines(rest, [line, ..processed])
                  }
                }
                Error(_) ->
                  process_heading_attribute_lines(rest, [line, ..processed])
              }
            }

            False -> process_heading_attribute_lines(rest, [line, ..processed])
          }
        }

        _, _ -> process_heading_attribute_lines(rest, [line, ..processed])
      }
    }
  }
}

// Clean heading text by removing any {#id} attributes
fn clean_heading_text(inlines: List(Inline)) -> List(Inline) {
  inlines
  |> list.map(fn(inline) {
    case inline {
      Text(text) -> {
        // Remove {#id} pattern from the text
        case string.split_once(text, " {#") {
          Ok(#(content, _)) -> Text(content)
          Error(_) -> inline
        }
      }
      _ -> inline
    }
  })
}

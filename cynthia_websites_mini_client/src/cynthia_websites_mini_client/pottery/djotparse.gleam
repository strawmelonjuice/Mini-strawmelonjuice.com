//// Djot is parsed using jot, then converted to lustre elements using jotkey/jot_to_lustre's logic, slightly modified to fit Cynthia's needs.

import cynthia_websites_mini_client/utils
import gleam/dict.{type Dict}
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

pub fn entry_to_conversion(djot: String) {
  djot
  |> jot.parse
  |> document_to_lustre
}

fn document_to_lustre(document: Document) {
  list.reverse(
    containers_to_lustre(document.content, document.references, [element.none()]),
  )
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
    Heading(attrs, level, inlines) -> {
      case level {
        1 ->
          html.h1(
            attributes_to_lustre(attrs, [
              attribute.class("text-4xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], inlines, refs),
          )
        2 ->
          html.h2(
            attributes_to_lustre(attrs, [
              attribute.class("text-3xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], inlines, refs),
          )
        3 ->
          html.h3(
            attributes_to_lustre(attrs, [
              attribute.class("text-2xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], inlines, refs),
          )
        4 ->
          html.h4(
            attributes_to_lustre(attrs, [
              attribute.class("text-xl font-bold text-accent"),
            ]),
            inlines_to_lustre([], inlines, refs),
          )
        5 ->
          html.h5(
            attributes_to_lustre(attrs, [
              attribute.class("text-lg font-bold text-accent"),
            ]),
            inlines_to_lustre([], inlines, refs),
          )
        _ ->
          html.h6(
            attributes_to_lustre(attrs, [
              attribute.class("font-bold text-accent"),
            ]),
            inlines_to_lustre([], inlines, refs),
          )
      }
    }
    Codeblock(attrs, language, content) -> {
      html.pre(
        attributes_to_lustre(attrs, [
          attribute.class(
            "bg-neutral text-neutral-content pl-4 block ml-2 mr-2 overflow-x-auto break-none whitespace-pre-wrap font-mono border-dotted border-2 border-neutral-content",
          ),
        ]),
        [
          html.code(
            case language {
              Some(lang) -> [attribute.class("language-" <> lang)]
              None -> []
            }
              |> list.append([
                attribute.class(
                  "bg-neutral text-neutral-content p-1 rounded-lg",
                ),
              ]),
            [html.text(content)],
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
    // Not sure if I want to support this...
    jot.RawBlock(content:) ->
      element.unsafe_raw_html(
        "div",
        "div",
        [attribute.class("djot-rawblock")],
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
    [] -> elements
    [inline, ..rest] -> {
      elements
      |> inline_to_lustre(inline, refs)
      |> inlines_to_lustre(rest, refs)
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
          Reference(..) -> {
            html.p([attribute.class("text-blue-500 underline")], [
              html.text(
                "Djot references are currently not supported by Cynthia Mini.",
              ),
            ])
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
    jot.Footnote(reference:) -> todo
    jot.MathDisplay(content:) -> todo
    jot.MathInline(content:) -> todo
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
        jot.Footnote(reference:) -> "[ footnotes are currently not supported ]"
        jot.MathDisplay(content:) ->
          "[ math display is currently not supported ]"
        jot.MathInline(content:) -> "[ math inline is currently not supported ]"
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

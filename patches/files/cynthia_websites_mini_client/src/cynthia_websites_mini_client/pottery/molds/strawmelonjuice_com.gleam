import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/utils
import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn page_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  // Determine if silly mode is allowed based on the path
  let silly_allowed =
    bool.negate(string.contains(model.path, "portfolio"))
    && bool.negate(string.starts_with(model.path, "!"))
  let hide_metadata_block =
    decode.run(
      result.unwrap(
        dict.get(variables, "hide_metadata_block"),
        dynamic.from(False),
      ),
      decode.bool,
    )
    |> result.unwrap(False)

  let hide_metadata_block_classonly = case hide_metadata_block {
    True -> " hidden"

    False -> ""
  }
  let #(badgies_wide, badgies_tall) = case silly_allowed {
    True -> {
      let badgies_inside = {
        [
          // Header for tags section
          html.div(
            [
              attribute.class(
                "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
              ),
            ],
            [html.text("Badgies")],
          ),
          html.div([attribute.class("p-3")], [
            html.div([attribute.class("flex flex-wrap gap-2")], [
              badges({
                let assert Ok(badges_json_) =
                  dict.get(model.other, "config_strawmelonjuice_badges")
                  as "badges json not found in config"
                let assert Ok(badges_json) =
                  decode.run(badges_json_, decode.string)
                  as "Could not decode badges config into a json string."
                let assert Ok(badge_list) =
                  json.parse(badges_json, decode.list(badge_decoder()))
                  as "Could not parse badges json into a proper list of badges."
                badge_list
              }),
            ]),
          ]),
        ]
      }
      #(
        html.div(
          [
            attribute.id("da-badgies"),
            attribute.class(
              "border border-base-300 rounded-md overflow-hidden mb-4 bg-base-300 hidden lg:block",
            ),
          ],
          badgies_inside,
        ),
        html.div(
          [
            attribute.id("le-badgies"),
            attribute.class(
              "border border-base-300 rounded-md overflow-hidden mt-4 bg-base-300 lg:hidden",
            ),
          ],
          badgies_inside,
        ),
      )
    }
    False -> #(element.none(), element.none())
  }
  // Load the primary navigation menu
  let menu = menu_1(model)

  // Extract required metadata
  let title =
    dict.get(variables, "title")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
    |> result.unwrap("")

  let description_option =
    dict.get(variables, "description")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
    |> result.unwrap("")
    |> string.to_option
    |> option.map(fn(_) {
      // If description is present, then give it as HTML
      dict.get(variables, "description_html")
      |> result.unwrap(dynamic.from(None))
      |> decode.run(decode.string)
      |> result.unwrap("")
    })

  let page_meta =
    html.div(
      [
        attribute.id("da-sidebar"),
        attribute.class(
          "w-full lg:sticky lg:top-4" <> hide_metadata_block_classonly,
        ),
      ],
      [
        case description_option {
          Some(description) -> {
            html.div(
              [attribute.class("flex flex-col lg:flex-row lg:gap-4 mb-4")],
              [
                // About section with description
                html.div(
                  [
                    attribute.class(
                      "w-full lg:w-1/2 border border-base-300 rounded-md overflow-hidden mb-4 lg:mb-0 bg-base-300",
                    ),
                  ],
                  [
                    html.div(
                      [
                        attribute.class(
                          "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
                        ),
                      ],
                      [html.text(title)],
                    ),
                    html.div([attribute.class("px-3 py-3 text-sm")], [
                      element.unsafe_raw_html("div", "div", [], description),
                    ]),
                  ],
                ),
              ],
            )
          }
          None -> element.none()
        },
        badgies_wide,
      ],
    )

  // Assemble the complete layout using the common layout function
  theme_common(
    content:,
    menu:,
    sidebars: #(page_meta, element.none()),
    underneath: badgies_tall,
    variables:,
    model:,
    is_post: False,
  )
}

type Badge {
  Badge(
    clickable_url: String,
    img_url: String,
    img_alt: String,
    img_title: String,
    text_badge: String,
  )
}

fn badge_decoder() -> decode.Decoder(Badge) {
  use clickable_url <- decode.field("href", decode.string)
  use img_url <- decode.field("src", decode.string)
  use img_alt <- decode.field("alt", decode.string)
  use img_title <- decode.field("title", decode.string)
  use text_badge <- decode.field("text_badge", decode.string)
  let clickable_url = case clickable_url {
    "self" -> img_url
    _ -> clickable_url
  }
  decode.success(Badge(
    clickable_url:,
    img_url:,
    img_alt:,
    img_title:,
    text_badge:,
  ))
}

type BadgeList =
  List(Badge)

fn badges(badge_list: BadgeList) -> Element(messages.Msg) {
  case badges_getter() {
    Ok(badges_) -> badges_
    Error(_) -> badges_builder(badge_list) |> badges_saver()
  }
}

/// Hides the footer and returns its paragraph innerHTML.
@external(javascript, "./strawmelonjuice_com_ffi.ts", "steal_footer")
fn steal_footer() -> String

/// The new tick system introduced a bug: Badges keep shuffling uncontrollably
/// This 'caches' them into a window object, so that they do not need to be reshuffled constantly.
@external(javascript, "./strawmelonjuice_com_ffi.ts", "badges_getter")
fn badges_getter() -> Result(Element(messages.Msg), Nil)

@external(javascript, "./strawmelonjuice_com_ffi.ts", "badges_saver")
fn badges_saver(badges: Element(messages.Msg)) -> Element(messages.Msg)

fn badges_builder(badge_list: BadgeList) -> Element(messages.Msg) {
  let badge_classes = "badge badge-dash badge-primary lg rounded-none m-1"
  let clickable_badge_classes = badge_classes <> " cursor-pointer"
  // Let's start by determining the badge types we currently have.
  // 1. A unclickable image badge
  // 3. A clickable image badge
  // 4. A clickable image+text badge
  list.map(badge_list, fn(badge_item) {
    let invalid = string.is_empty(badge_item.img_url)
    let clickable = bool.negate(string.is_empty(badge_item.clickable_url))
    let with_text = bool.negate(string.is_empty(badge_item.text_badge))
    case invalid, clickable, with_text {
      True, _, _ -> {
        // No badge.
        // maybe a placeholder.
        element.none()
      }
      _, False, False -> {
        // Case 1: Unclickable badge
        html.img([
          attribute.attribute("loading", "lazy"),
          attribute.class(badge_classes),
          attribute.attribute("title", badge_item.img_title),
          attribute.alt(badge_item.img_alt),
          attribute.src(badge_item.img_url),
        ])
      }
      _, False, True -> {
        // Case 2: Nonexistent case -- Unclickable, with text
        panic as "Nonexistent badge format"
      }
      _, True, False -> {
        // Case 3: Clickable image badge
        html.img([
          attribute.attribute("loading", "lazy"),
          attribute.class(clickable_badge_classes),
          attribute.attribute(
            "onclick",
            "window.open('" <> badge_item.clickable_url <> "');",
          ),
          attribute.attribute("title", "[Clickable] " <> badge_item.img_title),
          attribute.alt(badge_item.img_title),
          attribute.src(badge_item.img_url),
        ])
      }
      _, True, True -> {
        // Case 4: Clickable, with text
        html.div(
          [
            attribute.class(clickable_badge_classes),
            attribute.attribute(
              "onclick",
              "window.open('" <> badge_item.clickable_url <> "');",
            ),
          ],
          [
            html.img([
              attribute.attribute("loading", "lazy"),
              attribute.class("w-4 h-4"),
              attribute.attribute(
                "title",
                "[Clickable] " <> badge_item.img_title,
              ),
              attribute.alt(badge_item.img_alt),
              attribute.src(badge_item.img_url),
            ]),
            html.text(" " <> badge_item.text_badge),
          ],
        )
      }
    }
  })
  |> list.shuffle
  |> html.div([], _)
}

pub fn post_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  // Load the primary navigation menu
  let menu = menu_1(model)

  // Extract required metadata
  let assert Ok(description) =
    dict.get(variables, "description_html")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  let post_meta = #(
    html.div(
      [
        attribute.id("da-sidebar"),
        attribute.class("w-full"),
        // attribute.class("w-full lg:sticky lg:top-4"),
      ],
      [
        html.div([attribute.class("flex flex-col lg:flex-row lg:gap-4 mb-4")], [
          // About section with description
          html.div(
            [
              attribute.class(
                "w-full lg:w-1/2 border border-base-300 rounded-md overflow-hidden mb-4 lg:mb-0 bg-base-300",
              ),
            ],
            [
              html.div(
                [
                  attribute.class(
                    "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
                  ),
                ],
                [html.text("About")],
              ),
              html.div([attribute.class("px-3 py-3 text-sm")], [
                element.unsafe_raw_html("div", "div", [], description),
              ]),
            ],
          ),
          // Post information box
          html.div(
            [
              attribute.class(
                "w-full lg:w-1/2 border border-base-300 rounded-md overflow-hidden bg-base-300",
              ),
            ],
            [
              html.div(
                [
                  attribute.class(
                    "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
                  ),
                ],
                [html.text("Information")],
              ),
              html.div([attribute.class("divide-y divide-base-300")], [
                // Published date
                html.div(
                  [attribute.class("flex items-center gap-2 px-3 py-2")],
                  [
                    html.span(
                      [
                        attribute.class(
                          "i-tabler-calendar-event text-base-content/60",
                        ),
                        attribute.aria_hidden(True),
                      ],
                      [],
                    ),
                    html.div([attribute.class("text-sm")], [
                      html.text(
                        "Published "
                        <> {
                          variables
                          |> dict.get("date_published")
                          |> result.unwrap(dynamic.from(None))
                          |> decode.run(decode.string)
                          |> result.unwrap("unknown")
                        },
                      ),
                    ]),
                  ],
                ),
                // Last modified date
                html.div(
                  [attribute.class("flex items-center gap-2 px-3 py-2")],
                  [
                    html.span(
                      [
                        attribute.class("i-tabler-edit text-base-content/60"),
                        attribute.aria_hidden(True),
                      ],
                      [],
                    ),
                    html.div([attribute.class("text-sm")], [
                      html.text(
                        "Updated "
                        <> {
                          variables
                          |> dict.get("date_modified")
                          |> result.unwrap(dynamic.from(None))
                          |> decode.run(decode.string)
                          |> result.unwrap("unknown")
                        },
                      ),
                    ]),
                  ],
                ),
                html.div(
                  [attribute.class("flex items-center gap-2 px-3 py-2")],
                  [
                    html.span(
                      [
                        attribute.class(
                          "i-tabler-category text-base-content/60",
                        ),
                        attribute.aria_hidden(True),
                      ],
                      [],
                    ),
                    html.div([attribute.class("flex items-center gap-1")], [
                      html.text("Category: "),
                      html.span(
                        [
                          attribute.class(
                            "px-2 py-0.5 text-xs rounded-full font-medium bg-primary/15 text-primary-content",
                          ),
                        ]
                          |> list.append(
                            case
                              variables
                              |> dict.get("category")
                              |> result.unwrap(dynamic.from(None))
                              |> decode.run(decode.string)
                            {
                              Ok(category) -> [
                                event.on_click(messages.UserNavigateTo(
                                  "!/category/" <> category,
                                )),
                                attribute.class(
                                  "cursor-pointer hover:bg-primary/25",
                                ),
                              ]
                              Error(_) -> [
                                attribute.class(
                                  "cursor-not-allowed text-base-content/50",
                                ),
                              ]
                            },
                          ),
                        [
                          html.text(
                            variables
                            |> dict.get("category")
                            |> result.unwrap(dynamic.from(None))
                            |> decode.run(decode.string)
                            |> result.unwrap("unknown"),
                          ),
                        ],
                      ),
                    ]),
                  ],
                ),
              ]),
            ],
          ),
        ]),
      ],
    ),
    html.div([], [
      html.div(
        [
          attribute.id("da-tags"),
          attribute.class(
            "border border-base-300 rounded-md overflow-hidden mb-4 bg-base-300",
          ),
        ],
        [
          // Header for tags section
          html.div(
            [
              attribute.class(
                "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
              ),
            ],
            [html.text("Tags")],
          ),
          html.div([attribute.class("p-3")], [
            html.div(
              [attribute.class("flex flex-wrap gap-2")],
              variables
                |> dict.get("tags")
                |> result.unwrap(dynamic.from([]))
                |> decode.run(decode.list(decode.string))
                |> result.unwrap([])
                |> list.map(string.trim)
                |> list.map(fn(tag) {
                  html.a(
                    [
                      attribute.class(
                        "px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/15 text-primary-content hover:bg-primary/25",
                      ),
                      attribute.href("#!/tag/" <> tag),
                    ],
                    [html.text(tag)],
                  )
                }),
            ),
          ]),
        ],
      ),
    ]),
  )

  // Assemble the complete layout with sidebar content
  theme_common(
    content: content,
    menu: menu,
    sidebars: post_meta,
    underneath: html.div(
      [
        attribute.id("da-comments"),
        attribute.class(
          "border border-base-300 rounded-md mb-4 bg-base-300 h-full mt-4 ",
        ),
      ],
      [
        // Header for comments section
        html.div(
          [
            attribute.class(
              "bg-base-200 px-3 py-2 text-sm font-medium border-b border-base-300",
            ),
          ],
          [html.text("Comments")],
        ),
        html.div([attribute.class("h-full")], [
          html.div(
            [
              attribute.class(
                "flex flex-nowrap w-full h-[600px] overflow-y-scroll",
              ),
            ],
            [
              // Utterances comments will be loaded here
              {
                let comment_color_scheme = case dom.get_color_scheme() {
                  "dark" -> "dark-blue"
                  _ -> "github-dark-orange"
                }
                let assert Some(complete_data) = model.complete_data

                // Utterances script directly after main content
                html.script(
                  [
                    attribute.attribute("async", ""),
                    attribute.attribute("crossorigin", "anonymous"),
                    attribute.attribute("theme", comment_color_scheme),
                    attribute.attribute("issue-term", model.path),
                    attribute.attribute(
                      "repo",
                      complete_data.comment_repo |> option.unwrap(""),
                    ),
                    attribute.attribute(
                      "return-url",
                      utils.phone_home_url() <> "#" <> model.path,
                    ),
                    attribute.src("https://utteranc.es/client.js"),
                  ],
                  "",
                )
              },
              html.style(
                [],
                "
              .utterances {
                height: unset !important;
                overflow-y: auto !important;
              }
              .utterances-frame {
                position: unset !important;
                left: 0;
                right: 0;
                width: 100% !important;
                min-width: unset !important;
                max-width: unset !important;
                height: 90000px !important;
                border: 0;
              }
              ",
              ),
            ],
          ),
        ]),
      ],
    ),
    variables:,
    model:,
    is_post: True,
  )
}

/// Shared layout structure for both pages and posts
///
/// @param content The main page/post content
/// @param menu List of primary navigation menu elements
/// @param sidebar Sidebar content (post metadata or page header based on type)
/// @param variables Dictionary containing metadata for the page/post
/// @param model Model with application state
/// @return A complete HTML layout structure
fn theme_common(
  content content: Element(messages.Msg),
  menu menu: List(Element(messages.Msg)),
  sidebars sidebar: #(Element(messages.Msg), Element(messages.Msg)),
  underneath underneath: Element(messages.Msg),
  variables variables: Dict(String, Dynamic),
  model model: model_type.Model,
  is_post is_post: Bool,
) -> Element(messages.Msg) {
  let hide_metadata_block =
    decode.run(
      result.unwrap(
        dict.get(variables, "hide_metadata_block"),
        dynamic.from(False),
      ),
      decode.bool,
    )
    |> result.unwrap(False)

  let hide_metadata_block_classonly = case hide_metadata_block {
    True -> " hidden"

    False -> ""
  }
  let content =
    content |> heading_indicator_adder() |> social_media_classes_adder()
  let menu_is_open = result.is_ok(dict.get(model.other, "strawmelonmenu open"))
  // Extract site name and determine if this is a post
  let assert Ok(site_name) =
    dict.get(variables, "global_site_name")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)

  html.div(
    [
      attribute.id("content"),
      attribute.class("w-full h-screen overflow-y-auto bg-base-100"),
    ],
    [
      html.div(
        [
          attribute.class(
            "bg-base-100 border-b border-base-300 sticky top-0 z-10",
          ),
        ],
        [
          html.div([attribute.class("container mx-auto px-4 lg:px-5")], [
            html.div([attribute.class("flex items-center h-16")], [
              // Left side - site logo, name, and nav
              html.div([attribute.class("flex-1 flex items-center gap-4")], [
                // Logo and site name group
                html.div([attribute.class("flex items-center gap-2 mr-4")], [
                  html.span([attribute.class("text-xl text-base-content")], []),
                  html.a(
                    [
                      attribute.class(
                        "font-semibold text-base-content text-lg whitespace-nowrap",
                      ),
                      attribute.href("/"),
                    ],
                    [html.text(site_name)],
                  ),
                ]),
                html.div(
                  [attribute.class("max-w-lg w-full hidden sm:block mr-4")],
                  [
                    html.div(
                      [
                        attribute.class(
                          "flex items-center h-7 bg-base-200/70 border border-base-300 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary",
                        ),
                      ],
                      [
                        html.div(
                          [attribute.class("pl-2 text-base-content/60")],
                          [
                            html.span(
                              [attribute.class("i-tabler-search w-3.5 h-3.5")],
                              [],
                            ),
                          ],
                        ),
                        html.input([
                          attribute.class(
                            "w-full py-0.5 px-2 text-xs bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/50",
                          ),
                          attribute.placeholder("Search or jump to..."),
                          attribute.type_("text"),
                          event.on_input(messages.UserSearchTerm),
                        ]),
                      ],
                    ),
                  ],
                ),
                html.div([attribute.class("hidden xl:block flex-grow")], [
                  html.nav([attribute.class("flex h-full")], [
                    html.ul(
                      [
                        attribute.id("menu_1_inside"),
                        attribute.class(
                          "menu menu-horizontal bg-base-200 rounded-box",
                        ),
                      ],
                      menu,
                    ),
                  ]),
                ]),
              ]),
              html.div(
                [
                  attribute.class(
                    "flex items-center gap-2 text-base-content/70",
                  ),
                ],
                [
                  html.div([attribute.class("xl:hidden")], [
                    html.button(
                      [
                        attribute.class(
                          "p-1 rounded hover:bg-base-200 border border-transparent hover:border-base-300 fa fa-bars",
                        ),
                        attribute.aria_label("Toggle navigation"),
                        event.on_click(messages.UserToggleStrawmelonMenu),
                      ],
                      [
                        html.span(
                          [attribute.class("i-tabler-menu h-5 w-5")],
                          [],
                        ),
                      ],
                    ),
                  ]),
                ],
              ),
            ]),
          ]),
        ],
      ),
      // Mobile navigation drawer - shown only when menu_is_open is true
      case menu_is_open {
        True ->
          html.div(
            [
              attribute.class(
                "xl:hidden bg-base-100 border-b border-base-300 shadow-md",
              ),
            ],
            [
              html.div([attribute.class("container mx-auto px-4 py-3")], [
                // Mobile search input
                html.div([attribute.class("mb-3")], [
                  html.div(
                    [
                      attribute.class(
                        "flex items-center h-8 bg-base-200/70 border border-base-300 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary sm:hidden",
                      ),
                    ],
                    [
                      html.div([attribute.class("pl-3 text-base-content/60")], [
                        html.span(
                          [attribute.class("i-tabler-search w-4 h-4")],
                          [],
                        ),
                      ]),
                      html.input([
                        attribute.class(
                          "w-full py-1.5 px-2 text-sm bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/50",
                        ),
                        attribute.placeholder("Search or jump to..."),
                        attribute.type_("text"),
                        event.on_input(messages.UserSearchTerm),
                      ]),
                    ],
                  ),
                ]),
                // Mobile navigation items
                html.nav([], [
                  html.div(
                    [
                      attribute.class(
                        "text-sm font-medium text-base-content/60 mb-2 px-2",
                      ),
                    ],
                    [html.text("Navigation")],
                  ),
                  html.ul(
                    [
                      attribute.id("mobile_menu_items"),
                      attribute.class("flex flex-col space-y-1"),
                    ],
                    // Create mobile menu items directly from the model data
                    // instead of trying to transform the desktop menu elements
                    case dict.get(model.computed_menus, 1) {
                      Error(_) -> []
                      Ok(mobile_menu_items) -> {
                        list.map(mobile_menu_items, fn(item) {
                          // Convert item to tuple, this is not the best approach, but it works as well as refactoring for custom type here.
                          let item = {
                            let model_type.MenuItem(name:, to:) = item
                            #(name, to)
                          }
                          // Handle empty URLs as links to homepage
                          let item = case item.1 {
                            "" -> #(item.0, "/")
                            _ -> item
                          }

                          // Determine if this is the active page
                          let is_active = model.path == item.1

                          html.li([], [
                            html.a(
                              [
                                attribute.class(
                                  "flex items-center px-3 py-2 rounded-md icon"
                                  <> case is_active {
                                    True -> "bg-primary/10 text-primary"
                                    False ->
                                      "hover:bg-base-200 text-base-content/80"
                                  },
                                ),
                                attribute.href(
                                  utils.phone_home_url() <> "#" <> item.1,
                                ),
                                event.on_click(
                                  messages.UserToggleStrawmelonMenu,
                                ),
                              ],
                              [
                                html.div(
                                  [attribute.class("flex items-center gap-2")],
                                  [
                                    html.span(
                                      [
                                        attribute.class(
                                          "i-tabler-file "
                                          <> case is_active {
                                            True -> " text-primary"
                                            False -> " text-base-content/60"
                                          },
                                        ),
                                        attribute.aria_hidden(True),
                                      ],
                                      [],
                                    ),
                                    html.text(item.0),
                                  ],
                                ),
                              ],
                            ),
                          ])
                        })
                      }
                    },
                  ),
                ]),
              ]),
            ],
          )
        False -> html.div([], [])
      },
      // Main content area with container
      html.main(
        [
          attribute.class(
            "container mx-auto px-4 lg:px-5 py-6 w-screen min-h-[calc(100vh-10rem)]",
          ),
        ],
        [
          // Different layout for posts vs pages (desktop only)
          case !is_post {
            True -> {
              let maincontent =
                html.div([attribute.class("w-full lg:w-2/3")], [
                  html.div([attribute.class("mb-6")], [
                    html.h1(
                      [
                        attribute.class(
                          "text-2xl font-semibold text-base-content mb-4"
                          <> hide_metadata_block_classonly,
                        ),
                      ],
                      [
                        html.text(
                          variables
                          |> dict.get("title")
                          |> result.unwrap(dynamic.from(None))
                          |> decode.run(decode.string)
                          |> result.unwrap(""),
                        ),
                      ],
                    ),
                  ]),
                  html.div(
                    [
                      attribute.id("da-content-box"),
                      attribute.class(
                        "border border-base-300 rounded-md overflow-hidden bg-base-100",
                      ),
                    ],
                    [
                      html.div(
                        [
                          attribute.id("da-content"),
                          attribute.class("px-4 py-4 prose max-w-none"),
                        ],
                        [content],
                      ),
                    ],
                  ),
                ])
              html.div([attribute.class("flex flex-col lg:flex-row lg:gap-6")], [
                // Sidebar (1/3 width on desktop) - Put first in DOM for both mobile and desktop
                html.div([attribute.class("w-full lg:w-1/3 mb-6 lg:mb-0")], [
                  sidebar.0,
                  html.div([attribute.class("block lg:hidden mb-4")], [
                    maincontent,
                  ]),
                  sidebar.1,
                ]),
                // Main content area (2/3 width on desktop)
                html.div([attribute.class("hidden lg:block w-full h-full")], [
                  maincontent,
                ]),
              ])
            }
            False -> {
              // Page layout: Simplified, README-style layout with side-by-side layout on desktop
              html.div([attribute.class("flex flex-col lg:flex-row lg:gap-6")], [
                // Page header from sidebar parameter - displayed in a sidebar column on desktop
                html.div([attribute.class("w-full lg:w-1/3 mb-6 lg:mb-0")], [
                  sidebar.0,
                  sidebar.1,
                ]),
                // Content column - takes 2/3 width on desktop
                html.div([attribute.class("w-full lg:w-2/3")], [
                  html.div(
                    [
                      attribute.id("da-content-box"),
                      attribute.class(
                        "border border-base-300 rounded-md overflow-hidden bg-base-100",
                      ),
                    ],
                    [
                      html.div(
                        [
                          attribute.id("da-content"),
                          attribute.class("px-4 py-4 prose max-w-none"),
                        ],
                        [content],
                      ),
                    ],
                  ),
                ]),
              ])
            }
          },
          underneath,
        ],
      ),

      html.div(
        [attribute.class("border-t border-base-300 bg-base-100 mt-auto py-8")],
        [
          html.div([attribute.class("container mx-auto px-4 lg:px-5")], [
            html.div(
              [
                attribute.class(
                  "flex flex-col lg:flex-row items-center justify-between gap-4",
                ),
              ],
              [
                html.div([attribute.class("flex items-center gap-2")], [
                  html.span(
                    [attribute.class("i-tabler-book text-base-content/60")],
                    [],
                  ),
                  html.span([attribute.class("text-sm text-base-content/60")], [
                    html.text(site_name),
                  ]),
                ]),
                html.p([attribute.class("text-xs text-base-content/60")], [
                  element.unsafe_raw_html(
                    "div",
                    "div",
                    [],
                    steal_footer()
                      |> string.replace(
                        "dark:text-sky-600 text-sky-800 underline",
                        "link link-primary font-semibold",
                      ),
                  ),
                ]),
                html.p([attribute.class("text-xs text-base-content/60")], [
                  html.text("Using a "),
                  html.a(
                    [
                      attribute.class("link link-primary font-semibold"),
                      attribute.href(
                        "https://github.com/strawmelonjuice/Mini-strawmelonjuice.com",
                      ),
                    ],
                    [html.text("customised")],
                  ),
                  html.text(" theme"),
                ]),
              ],
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn menu_1(from model: model_type.Model) -> List(Element(messages.Msg)) {
  // Get the current URL hash to identify the active page
  let hash = model.path
  let content = model.computed_menus

  // Extract level 1 menu items (main navigation)
  case dict.get(content, 1) {
    Error(_) -> []
    // Return empty list if no menu items
    Ok(menu_items) -> {
      list.map(menu_items, fn(menu_item) {
        // Convert item to tuple, this is not the best approach, but it works as well as refactoring for custom type here.
        let item = {
          let model_type.MenuItem(name:, to:) = menu_item
          #(name, to)
        }
        // Handle empty URLs as links to homepage
        let item = case item.1 {
          "" -> #(item.0, "/")
          _ -> item
        }

        html.li([attribute.class("")], [
          html.a(
            [
              attribute.class(
                "btn btn-sm "
                <> case hash == item.1 {
                  True -> "menu-active btn-secondary"
                  False -> "btn-primary"
                },
              ),
              attribute.href(utils.phone_home_url() <> "#" <> item.1),
            ],
            [
              html.div([attribute.class("")], [
                html.span(
                  [
                    attribute.class(
                      "i-tabler-file"
                      <> case hash == item.1 {
                        True -> " text-primary"
                        False -> " text-base-content/60"
                      },
                    ),
                    attribute.aria_hidden(True),
                  ],
                  [],
                ),
                html.text(item.0),
              ]),
            ],
          ),
        ])
      })
    }
  }
}

/// In case you wonder why this function exists:
/// I want to add heading level indicators (H1, H2, etc.) next to
/// each heading in the content for better visual structure during editing.
/// This function takes the content element, converts it to a string,
/// performs string replacements to insert the indicators, and then
/// converts it back to an element.
///
/// Yes that means tailwind knows. Yes that is why.
fn heading_indicator_adder(content: Element(a)) -> Element(a) {
  let badge_generic =
    " m-auto inline-block align-top badge badge-soft  badge-xs"
  let badge_ghost = "<span class=\"badge-ghost " <> badge_generic <> "\">"

  element.to_string(content)
  |> string.replace(
    "</h1>",
    badge_ghost <> "H1</div></h1><div class='divider'>~~~</div>",
  )
  |> string.replace(
    "</h2>",
    badge_ghost <> "H2</div></h2><div class='divider'>~~</div>",
  )
  |> string.replace(
    "</h3>",
    badge_ghost <> "H3</div></h3><div class='divider'>~</div>",
  )
  |> string.replace("</h4>", badge_ghost <> "H4</div></h4>")
  |> string.replace("</h5>", badge_ghost <> "H5</div></h5>")
  |> string.replace("</h6>", badge_ghost <> "H6</div></h6>")
  |> element.unsafe_raw_html("div", "div", [], _)
}

/// Adds social media classes to elements that require them
/// just a replace function to make tailwind happy
fn social_media_classes_adder(content: Element(a)) -> Element(a) {
  element.to_string(content)
  |> string.replace(
    "class=\"social-media-icons\"",
    "class=\"grid grid-flow-col gap-4\"",
  )
  |> element.unsafe_raw_html("div", "div", [], _)
}

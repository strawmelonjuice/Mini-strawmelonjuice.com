import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/utils
import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
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
      [attribute.id("da-sidebar"), attribute.class("w-full md:sticky md:top-4")],
      [
        case description_option {
          Some(description) -> {
            html.div(
              [attribute.class("flex flex-col md:flex-row md:gap-4 mb-4")],
              [
                // About section with description
                html.div(
                  [
                    attribute.class(
                      "w-full md:w-1/2 border border-base-300 rounded-md overflow-hidden mb-4 md:mb-0 bg-base-300",
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
        case silly_allowed {
          True ->
            html.div(
              [
                attribute.id("da-badgies"),
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
                  [html.text("Badgies")],
                ),
                html.div([attribute.class("p-3")], [
                  html.div([attribute.class("flex flex-wrap gap-2")], [badges()]),
                ]),
              ],
            )
          False -> element.none()
        },
      ],
    )

  // Assemble the complete layout using the common layout function
  theme_common(content, menu, page_meta, variables, model)
}

fn badges() -> Element(messages.Msg) {
  let badge_classes = "badge badge-dash badge-primary lg rounded-none m-1"
  let clickable_badge_classes = badge_classes <> " cursor-pointer"
  html.div(
    [],
    [
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute("title", "intersectional feminism!"),
        attribute.alt("feminism"),
        attribute.src("/assets/img/badges/feminism.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute(
          "onclick",
          "window.open('/assets/img/badges/blinkiesCafe-xD.gif');",
        ),
        attribute.attribute(
          "title",
          "[Clickable] This page works better on a computer than on a smartphone :3",
        ),
        attribute.alt(
          "This site works better on a computer than on a smartphone :3",
        ),
        attribute.src("/assets/img/badges/blinkiesCafe-xD.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute(
          "onclick",
          "window.open('https://www.tumblr.com/strawmelonjuice');",
        ),
        attribute.attribute("title", "[Clickable] Tumblr Tumblr Tumblr"),
        attribute.alt("Tumblr"),
        attribute.src("/assets/img/badges/blinkiesCafe-tumblr-grrll.gif"),
      ]),
      html.div([attribute.class(clickable_badge_classes)], [
        html.img([
          attribute.attribute("loading", "lazy"),
          attribute.class("w-4 h-4"),
          attribute.attribute("onclick", "window.open('https://gleam.run/');"),
          attribute.attribute("title", "[Clickable] Written in Gleam"),
          attribute.alt(""),
          attribute.src("https://gleam.run/images/lucy/lucy.svg"),
        ]),
        html.text(" Made with Gleam"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute(
          "onclick",
          "window.open('https://yesterweb.org/no-to-web3/');",
        ),
        attribute.attribute("title", "[Clickable] Crypto's ewie."),
        attribute.alt("badge saying 'Keep the web free, say no to web3'"),
        attribute.src(
          "https://yesterweb.org/no-to-web3/img/roly-saynotoweb3.gif",
        ),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute(
          "onclick",
          "window.open('/assets/img/badges/blinkiesCafe-autism.gif');",
        ),
        attribute.attribute("title", "[Clickable] brain go brrr"),
        attribute.alt("autism"),
        attribute.src("/assets/img/badges/blinkiesCafe-autism.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute(
          "onclick",
          "window.open('https://www.mozilla.org/nl/firefox/new/?redirect_source=firefox-com');",
        ),
        attribute.attribute("title", "[Clickable] GET FIREFOX!!"),
        attribute.alt("Get Firefox"),
        attribute.src("/assets/img/badges/getfirefox.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute(
          "onclick",
          "window.open('/assets/img/badges/blinkiesCafe-L1.gif');",
        ),
        attribute.attribute("title", "[Clickable] AUTISM!"),
        attribute.alt("I GOT AUTISM!"),
        attribute.src("/assets/img/badges/blinkiesCafe-L1.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute("onclick", "window.open('https://polymc.org/');"),
        attribute.attribute("title", "[Clickable] block game good"),
        attribute.alt("minecraft"),
        attribute.src("/assets/img/badges/minecraft.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute("title", "nerd"),
        attribute.alt("nerd"),
        attribute.src("/assets/img/badges/nerd.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute("title", "FUCK NAZIS!"),
        attribute.alt("Fuck nazis"),
        attribute.src("/assets/img/badges/fucknazis.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute(
          "title",
          "NFTs are thrash, and a perfect way to spend money on destroying the world.",
        ),
        attribute.alt("anti-nft's"),
        attribute.src("/assets/img/badges/antinft.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute("title", "arch linux btw heheh"),
        attribute.alt("Run linux"),
        attribute.src("/assets/img/badges/linux80x15.png"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute("title", "Being a princess is a full time job <3"),
        attribute.alt("Being a princess is a full time job"),
        attribute.src("/assets/img/badges/beingaprincessisafulltimejob.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute("title", "We survived! We all did!"),
        attribute.alt("Y2K-compliant"),
        attribute.src("/assets/img/badges/y2k-compliant.gif"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(badge_classes),
        attribute.attribute(
          "title",
          "I'm trans, and... girls... are... awesome!",
        ),
        attribute.alt("trans-lesbian flag"),
        attribute.src("/assets/img/badges/transles80x31.png"),
      ]),
      html.img([
        attribute.attribute("loading", "lazy"),
        attribute.class(clickable_badge_classes),
        attribute.attribute("onclick", "window.open('https://blinkies.cafe');"),
        attribute.attribute(
          "title",
          "[Clickable] blinkies.cafe | make your own blinkies!",
        ),
        attribute.alt("blinkies.cafe"),
        attribute.src("https://blinkies.cafe/b/display/blinkiesCafe-badge.gif"),
      ]),
    ]
      |> list.shuffle,
  )
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

  let post_meta =
    html.div(
      [attribute.id("da-sidebar"), attribute.class("w-full md:sticky md:top-4")],
      [
        html.div([attribute.class("flex flex-col md:flex-row md:gap-4 mb-4")], [
          // About section with description
          html.div(
            [
              attribute.class(
                "w-full md:w-1/2 border border-base-300 rounded-md overflow-hidden mb-4 md:mb-0 bg-base-300",
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
                "w-full md:w-1/2 border border-base-300 rounded-md overflow-hidden bg-base-300",
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
                            "px-2 py-0.5 text-xs rounded-full font-medium bg-primary/15 text-primary",
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
                          "px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/15 text-primary hover:bg-primary/25",
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
      ],
    )

  // Assemble the complete layout with sidebar content
  theme_common(content, menu, post_meta, variables, model)
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
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  sidebar: Element(messages.Msg),
  variables: Dict(String, Dynamic),
  model: model_type.Model,
) -> Element(messages.Msg) {
  let menu_is_open = result.is_ok(dict.get(model.other, "strawmelonmenu open"))
  // Extract site name and determine if this is a post
  let assert Ok(site_name) =
    dict.get(variables, "global_site_name")
    |> result.unwrap(dynamic.from(None))
    |> decode.run(decode.string)
  let is_post =
    {
      dict.get(variables, "content_type")
      |> result.unwrap(dynamic.from(None))
      |> decode.run(decode.string)
    }
    == Ok("post")

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
                html.div([attribute.class("hidden md:block flex-grow")], [
                  html.nav([attribute.class("flex h-full")], [
                    html.ul(
                      [
                        attribute.id("menu_1_inside"),
                        attribute.class(
                          "menu menu-vertical lg:menu-horizontal bg-base-200 rounded-box",
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
                  html.div([attribute.class("md:hidden")], [
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
                "md:hidden bg-base-100 border-b border-base-300 shadow-md",
              ),
            ],
            [
              html.div([attribute.class("container mx-auto px-4 py-3")], [
                // Mobile search input
                html.div([attribute.class("mb-3")], [
                  html.div(
                    [
                      attribute.class(
                        "flex items-center h-8 bg-base-200/70 border border-base-300 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary",
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
          // Different layout for posts vs pages
          case is_post {
            True -> {
              html.div([attribute.class("flex flex-col md:flex-row md:gap-6")], [
                // Sidebar (1/3 width on desktop) - Put first in DOM for both mobile and desktop
                html.div([attribute.class("w-full md:w-1/3 mb-6 md:mb-0")], [
                  sidebar,
                ]),
                // Main content area (2/3 width on desktop)
                html.div([attribute.class("w-full md:w-2/3")], [
                  html.div([attribute.class("mb-6")], [
                    html.h1(
                      [
                        attribute.class(
                          "text-2xl font-semibold text-base-content mb-4",
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
                ]),
              ])
            }
            False -> {
              // Page layout: Simplified, README-style layout with side-by-side layout on desktop
              html.div([attribute.class("flex flex-col md:flex-row md:gap-6")], [
                // Page header from sidebar parameter - displayed in a sidebar column on desktop
                html.div([attribute.class("w-full md:w-1/3 mb-6 md:mb-0")], [
                  sidebar,
                ]),
                // Content column - takes 2/3 width on desktop
                html.div([attribute.class("w-full md:w-2/3")], [
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
        ],
      ),
      html.div(
        [attribute.class("border-t border-base-300 bg-base-100 mt-auto py-8")],
        [
          html.div([attribute.class("container mx-auto px-4 lg:px-5")], [
            html.div(
              [
                attribute.class(
                  "flex flex-col md:flex-row items-center justify-between gap-4",
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

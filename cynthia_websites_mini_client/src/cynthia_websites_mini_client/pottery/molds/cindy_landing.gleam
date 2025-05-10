//// Cindy Landing Layout module
////
//// Special layout optimized for landing pages, derived from Cindy Simple.
//// Post layout remains identical to cindy-simple, but pages get special treatment.

// Common imports for layouts
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/option
import gleam/result
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

import cynthia_websites_mini_client/pottery/molds/cindy_simple.{menu_1}

/// cindy-landing layout for pages - optimized for landing page experience with:
/// - Full-width hero section with large title
/// - Prominent call-to-action area
/// - Cleaner layout with less distractions
///
/// Dict keys:
/// - `content`
pub fn page_layout(
  from content: Element(messages.Msg),
  with variables: Dict(String, Dynamic),
  store model: model_type.Model,
) -> Element(messages.Msg) {
  let menu = menu_1(model)
  let assert Ok(title) =
    decode.run(
      result.unwrap(dict.get(variables, "title"), dynamic.from(option.None)),
      decode.string,
    )
    as "Could not determine title"
  let assert Ok(description) =
    decode.run(
      result.unwrap(
        dict.get(variables, "description_html"),
        dynamic.from(option.None),
      ),
      decode.string,
    )

  // Build the landing page header - larger and more prominent
  let landing_header =
    html.div(
      [
        attribute.class(
          "landing-hero mb-8 p-6 bg-gradient-to-r from-base-200 to-base-300 rounded-lg shadow-lg",
        ),
      ],
      [
        html.h1(
          [
            attribute.class(
              "font-bold text-4xl md:text-5xl text-center text-base-content mb-4",
            ),
          ],
          [html.text(title)],
        ),
        html.div([attribute.class("max-w-3xl mx-auto")], [
          element.unsafe_raw_html(
            "aside",
            "div",
            [attribute.class("text-lg text-center text-base-content/80")],
            description,
          ),
        ]),
      ],
    )

  // Create a page layout that puts more emphasis on content
  html.div([attribute.class("break-words")], [landing_header])
  |> landing_common(content, menu, _, variables)
}

/// Special common layout for landing pages: 
/// - More focused design
/// - Content centered and emphasized
/// - Full width content area
/// - Optional sidebar removed from view by default
fn landing_common(
  content: Element(messages.Msg),
  menu: List(Element(messages.Msg)),
  post_meta: Element(messages.Msg),
  variables: Dict(String, Dynamic),
) {
  let assert Ok(site_name) = {
    dict.get(variables, "global_site_name")
    |> result.unwrap(dynamic.from(option.None))
    |> decode.run(decode.string)
  }
  html.div([attribute.id("content"), attribute.class("w-full mb-2")], [
    html.span([], [
      html.div(
        [
          attribute.class(
            "grid grid-cols-6 grid-rows-12 gap-0 w-screen h-screen bg-base-100",
          ),
        ],
        [
          // Menu and site name - with adjusted styling for landing pages
          html.div(
            [
              attribute.class(
                "col-span-6 p-4 m-0 bg-base-300/50 backdrop-blur-sm flex sticky top-0 z-10",
              ),
            ],
            [
              html.div(
                [attribute.class("flex-auto w-3/12 flex items-stretch")],
                [
                  html.span(
                    [
                      attribute.class(
                        "text-center self-center font-bold btn btn-ghost text-2xl",
                      ),
                    ],
                    [html.text(site_name)],
                  ),
                ],
              ),
              // Minimalist search input that doesn't draw too much attention
              html.div(
                [
                  attribute.class(
                    "flex-auto w-4/12 flex items-center justify-center",
                  ),
                ],
                [
                  html.div(
                    [
                      attribute.class(
                        "relative w-full max-w-xs opacity-70 hover:opacity-100 transition-opacity",
                      ),
                    ],
                    [
                      html.div(
                        [
                          attribute.class(
                            "flex items-center h-8 bg-base-200/60 border border-base-300/50 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary w-full",
                          ),
                        ],
                        [
                          html.span(
                            [attribute.class("pl-3 text-base-content/60")],
                            [
                              html.span(
                                [attribute.class("i-tabler-search w-4 h-4")],
                                [],
                              ),
                            ],
                          ),
                          html.input([
                            attribute.class(
                              "w-full py-1.5 px-2 text-sm bg-transparent border-none focus:outline-none text-base-content placeholder-base-content/50",
                            ),
                            attribute.placeholder("Search..."),
                            attribute.type_("text"),
                            event.on_input(messages.UserSearchTerm),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Menu styled to be more subtle
              html.div([attribute.class("flex-auto w-5/12")], [
                html.menu([attribute.class("text-right")], [
                  html.ul(
                    [
                      attribute.id("menu_1_inside"),
                      attribute.class(
                        "menu menu-horizontal bg-base-200/60 backdrop-blur-sm rounded-box",
                      ),
                    ],
                    menu,
                  ),
                ]),
              ]),
            ],
          ),
          // Content - full width for landing pages
          html.div(
            [
              attribute.class(
                "col-span-6 row-span-11 row-start-2 overflow-auto min-h-full p-6 md:p-8 flex flex-col items-center",
              ),
            ],
            [
              html.div([attribute.class("w-full max-w-5xl")], [
                post_meta,
                content,
              ]),
            ],
          ),
        ],
      ),
    ]),
  ])
}

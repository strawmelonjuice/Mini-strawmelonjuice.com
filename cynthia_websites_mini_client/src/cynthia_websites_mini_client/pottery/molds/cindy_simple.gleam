//// Cindy Simple Layout module
////
//// Default OOTB layout for Cynthia Mini.

// Common imports for layouts
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type
import cynthia_websites_mini_client/utils
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode.{type Dynamic}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// cindy layout for pages.
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
  html.div([attribute.class("break-words")], [
    html.h3(
      [attribute.class("font-bold text-2xl text-center text-base-content")],
      [html.text(title)],
    ),
    element.unsafe_raw_html("aside", "aside", [], description),
  ])
  |> cindy_common(content, menu, _, variables)
}

pub fn post_layout(
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
  let assert Ok(description) =
    decode.run(
      result.unwrap(
        dict.get(variables, "description_html"),
        dynamic.from(option.None),
      ),
      decode.string,
    )
  html.div([], [
    html.div([], [
      html.h3(
        [attribute.class("font-bold text-2xl text-center text-base-content")],
        [html.text(title)],
      ),
      element.unsafe_raw_html("aside", "aside", [], description),
    ]),
    html.div([attribute.class("grid grid-cols-2 grid-rows-4 gap-2")], [
      // ----------------------
      html.div([], []),
      html.div([], []),
      // ----------------------
      html.b([attribute.class("font-bold")], [html.text("Published")]),
      html.div([], [
        html.text(
          {
            decode.run(
              result.unwrap(
                dict.get(variables, "date_published"),
                dynamic.from("unknown"),
              ),
              decode.string,
            )
          }
          |> result.unwrap("unknown"),
        ),
      ]),
      // ----------------------
      html.b([attribute.class("font-bold")], [html.text("Modified")]),
      html.div([], [
        html.text(
          {
            decode.run(
              result.unwrap(
                dict.get(variables, "date_modified"),
                dynamic.from("unknown"),
              ),
              decode.string,
            )
          }
          |> result.unwrap("unknown"),
        ),
      ]),
      // ----------------------
      html.div([], [
        html.b([attribute.class("font-bold")], [html.text("Category")]),
      ]),
      html.div([], [
        html.text(
          decode.run(
            result.unwrap(
              dict.get(variables, "category"),
              dynamic.from("unknown"),
            ),
            decode.string,
          )
          |> result.unwrap("unknown"),
        ),
      ]),
    ]),
    html.div([attribute.class("grid grid-cols-1 grid-rows-1 gap-2")], [
      html.div([], [
        html.b([attribute.class("font-bold")], [html.text("Tags")]),
        html.div(
          [],
          variables
            |> dict.get("tags")
            |> result.unwrap(dynamic.from([]))
            |> decode.run(decode.list(decode.string))
            |> result.unwrap([])
            |> list.map(string.trim)
            |> list.map(fn(tag) {
              html.a(
                [
                  attribute.class("btn btn-sm btn-outline btn-primary"),
                  attribute.href("#!/tag/" <> tag),
                ],
                [html.text(tag)],
              )
            }),
        ),
      ]),
    ]),
  ])
  |> cindy_common(content, menu, _, variables)
}

fn cindy_common(
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
            "grid grid-cols-5 grid-rows-12 gap-0 w-screen h-screen bg-base-100",
          ),
        ],
        [
          // Menu and site name
          html.div([attribute.class("col-span-5 p-2 m-0 bg-base-300 flex")], [
            html.div([attribute.class("flex-auto w-3/12 flex items-stretch")], [
              html.span(
                [
                  attribute.class(
                    "text-center self-center font-bold btn btn-ghost text-xl",
                  ),
                ],
                [html.text(site_name)],
              ),
            ]),
            // Add search input field between site name and menu
            html.div(
              [
                attribute.class(
                  "flex-auto w-4/12 flex items-center justify-center",
                ),
              ],
              [
                html.div([attribute.class("relative w-full max-w-xs")], [
                  html.div(
                    [
                      attribute.class(
                        "flex items-center h-8 bg-base-200/80 border border-base-300 rounded-md hover:bg-base-200 focus-within:bg-base-100 focus-within:border-primary w-full",
                      ),
                    ],
                    [
                      html.span([attribute.class("pl-3 text-base-content/60")], [
                        html.span(
                          [attribute.class("i-tabler-search w-4 h-4")],
                          [],
                        ),
                      ]),
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
                ]),
              ],
            ),
            html.div([attribute.class("flex-auto w-5/12")], [
              html.menu([attribute.class("text-right")], [
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
          // Content
          html.div(
            [
              attribute.class(
                "col-span-5 row-span-7 row-start-2 md:col-span-4 md:row-span-11 md:col-start-2 md:row-start-2 overflow-auto min-h-full p-4",
              ),
            ],
            [content, html.br([])],
          ),
          // Post meta
          html.div(
            [
              attribute.class(
                "col-span-5 row-span-4 row-start-9 md:row-span-8 md:col-span[] md:col-start-1 md:row-start-2 min-h-full bg-base-200 rounded-br-2xl overflow-auto w-full md:w-fit md:max-w-[20VW] md:p-2 break-words",
              ),
            ],
            [post_meta],
          ),
        ],
      ),
    ]),
  ])
}

/// Cindy Simple only has one menu, shown on the top of the page. But we still count it as menu 1.
pub fn menu_1(from model: model_type.Model) -> List(Element(messages.Msg)) {
  let hash = model.path
  let content = model.computed_menus
  case dict.get(content, 1) {
    Error(_) -> []
    Ok(dookie) -> {
      list.map(dookie, fn(a) {
        let a = case a.1 {
          "" -> #(a.0, "/")
          _ -> a
        }
        html.li([], [
          html.a(
            [
              attribute.class({
                case hash == a.1 {
                  True -> "menu-active menu-focused active"
                  False -> ""
                }
              }// <> " bg-secondary link-neutral-200 hover:link-secondary border-solid border-2 border-primary-content",
              ),
              attribute.href(utils.phone_home_url() <> "#" <> a.1),
            ],
            [html.text(a.0)],
          ),
        ])
      })
    }
  }
}

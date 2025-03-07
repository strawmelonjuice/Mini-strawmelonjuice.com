import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/dom
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import plinth/browser/document as plinth_document
import plinth/browser/element as plinth_element
import plinth/browser/window as plinth_window
import plinth/javascript/console

/// Molds is the name we use for templating here.
pub fn into(
  layout layout: String,
  for theme_type: String,
  store store: clientstore.ClientStore,
  is priority: Bool,
) -> fn(Element(a), Dict(String, String)) -> element.Element(a) {
  let is_post_not_page = case theme_type {
    "post" -> True
    "page" -> False
    _ -> panic as "Unknown content type"
  }
  case layout {
    "cindy" -> {
      case is_post_not_page {
        False -> fn(a: Element(a), b: Dict(String, String)) -> Element(a) {
          cindy_page(a, b, store, priority)
        }
        True -> fn(a: Element(a), b: Dict(String, String)) -> Element(a) {
          cindy_post(a, b, store, priority)
        }
      }
    }
    other -> {
      let f = "Unknown layout name: " <> other
      panic as f
    }
  }
}

/// Update the menu in the layout without rerendering the whole page.
pub fn retroactive_menu_update(store: clientstore.ClientStore) {
  case plinth_document.query_selector("#content") {
    Ok(elm) -> {
      let assert Ok(layout_name) = plinth_element.dataset_get(elm, "layout")
      let res = clientstore.pull_menus(store)
      case layout_name {
        "cindy" -> {
          let temp_menu =
            res
            |> cindy_menu_1()
            |> html.div(
              [
                attribute.id(
                  "temporary_menu_items_while_retroactively_updating_menu",
                ),
                attribute.class("hidden"),
              ],
              _,
            )
            |> element.to_string()
          let assert Ok(menu_1) =
            plinth_document.query_selector("#menu_1_inside")
          plinth_element.set_inner_html(menu_1, temp_menu)
          let assert Ok(temp_menu) =
            plinth_document.query_selector(
              // Makes this quite expensive but the retroactive_menu_update is not called often for that reason already.
              "#temporary_menu_items_while_retroactively_updating_menu",
            )
          let menu = dom.get_inner_html(temp_menu)
          plinth_element.remove(temp_menu)
          plinth_element.set_inner_html(menu_1, menu)
        }
        other -> {
          let f = "Unknown layout name: " <> other
          panic as f
        }
      }
    }
    Error(_) -> {
      console.warn("No content element found (yet).")
    }
  }
}

/// cindy layout for pages.
///
/// Dict keys:
/// - `content`
fn cindy_page(
  from content: Element(a),
  with variables: Dict(String, String),
  store store: clientstore.ClientStore,
  is priority: Bool,
) -> Element(a) {
  let menu = case priority {
    False -> {
      clientstore.pull_menus(store)
      |> cindy_menu_1()
    }
    True -> []
  }
  let assert Ok(title) = dict.get(variables, "title")
  let assert Ok(description) = dict.get(variables, "description_html")
  html.div([attribute.class("break-words")], [
    html.h3(
      [attribute.class("font-bold text-2xl text-center text-base-content")],
      [html.text(title)],
    ),
    html.aside(
      [attribute.attribute("dangerous-unescaped-html", description)],
      [],
    ),
  ])
  |> cindy_common(content, menu, _, variables)
}

fn cindy_post(
  from content: Element(a),
  with variables: Dict(String, String),
  store store: clientstore.ClientStore,
  is priority: Bool,
) -> Element(a) {
  let menu = case priority {
    False -> {
      clientstore.pull_menus(store)
      |> cindy_menu_1()
    }
    True -> []
  }
  let assert Ok(title) = dict.get(variables, "title")
  let assert Ok(description) = dict.get(variables, "description_html")
  html.div([], [
    html.div([], [
      html.h3(
        [attribute.class("font-bold text-2xl text-center text-base-content")],
        [html.text(title)],
      ),
      html.aside(
        [attribute.attribute("dangerous-unescaped-html", description)],
        [],
      ),
    ]),
    html.div([attribute.class("grid grid-cols-2 grid-rows-4 gap-2")], [
      // ----------------------
      html.div([], []),
      html.div([], []),
      // ----------------------
      html.b([attribute.class("font-bold")], [html.text("Published")]),
      html.div([], [
        html.text(
          variables |> dict.get("date_published") |> result.unwrap("unknown"),
        ),
      ]),
      // ----------------------
      html.b([attribute.class("font-bold")], [html.text("Modified")]),
      html.div([], [
        html.text(
          variables |> dict.get("date_modified") |> result.unwrap("unknown"),
        ),
      ]),
      // ----------------------
      html.div([], [
        html.b([attribute.class("font-bold")], [html.text("Category")]),
      ]),
      html.div([], [
        html.text(variables |> dict.get("category") |> result.unwrap("unknown")),
      ]),
    ]),
    html.div([attribute.class("grid grid-cols-1 grid-rows-1 gap-2")], [
      html.div([], [
        html.b([attribute.class("font-bold")], [html.text("Tags")]),
        html.div(
          [],
          variables
            |> dict.get("tags")
            |> result.unwrap("")
            |> string.split(",")
            |> list.map(fn(tag) {
              let tag = tag |> string.trim()
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
  content: Element(a),
  menu: List(Element(a)),
  post_meta: Element(a),
  variables: Dict(String, String),
) {
  let assert Ok(site_name) = dict.get(variables, "global_site_name")
  html.div(
    [
      attribute.id("content"),
      attribute.attribute("data-layout", "cindy"),
      attribute.class("w-full mb-2"),
    ],
    [
      html.span([], [
        html.div(
          [
            attribute.class(
              "grid grid-cols-5 grid-rows-12 gap-0 w-screen h-screen",
            ),
          ],
          [
            // Menu and site name
            html.div([attribute.class("col-span-5 p-2 m-0 bg-base-300 flex")], [
              html.div(
                [attribute.class("flex-auto w-3/12 flex items-stretch")],
                [
                  html.span(
                    [
                      attribute.class(
                        "text-center self-center font-bold btn btn-ghost text-xl",
                      ),
                    ],
                    [html.text(site_name)],
                  ),
                ],
              ),
              html.div([attribute.class("flex-auto w-9/12")], [
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
    ],
  )
}

fn cindy_menu_1(
  from content: Dict(Int, List(#(String, String))),
) -> List(Element(a)) {
  let assert Ok(hash) = plinth_window.get_hash()
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
              attribute.href("/#" <> a.1),
            ],
            [html.text(a.0)],
          ),
        ])
      })
    }
  }
}

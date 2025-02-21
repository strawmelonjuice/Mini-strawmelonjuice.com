import cynthia_websites_mini_client/datamanagement/clientstore
import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import plinth/javascript/console

/// Molds is the name we use for templating here.
pub fn into(
  layout layout: String,
  for theme_type: String,
  store store: clientstore.ClientStore,
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
          cyndy_page(a, b, store)
        }
        True -> fn(a: Element(a), b: Dict(String, String)) -> Element(a) {
          cyndy_post(a, b, store)
        }
      }
    }
    other -> {
      let f = "Unknown layout name: " <> other
      panic as f
    }
  }
}

/// Cyndy layout for pages.
///
/// Dict keys:
/// - `content`
fn cyndy_page(
  from content: Element(a),
  with variables: Dict(String, String),
  store store: clientstore.ClientStore,
) -> Element(a) {
  console.info("Variables: \n\t" <> string.inspect(variables))
  let menus = clientstore.pull_menus(store)
  html.div([attribute.id("content"), attribute.class("w-full mb-2")], [
    html.span([], [
      html.div(
        [
          attribute.class(
            "grid grid-cols-5 grid-rows-12 gap-2 w-screen h-screen",
          ),
        ],
        [
          html.div(
            [
              attribute.class(
                "col-span-4 row-span-11 col-start-2 row-start-2 overflow-auto min-h-full relative m-0",
              ),
            ],
            [content],
          ),
          html.div([attribute.class("col-span-5 p-0 m-0")], [
            html.text("Menu 1 goes here"),
          ]),
          html.div(
            [attribute.class("row-span-8 col-start-1 row-start-2 min-h-full")],
            [html.text("Post-meta (if any) goes here")],
          ),
        ],
      ),
    ]),
  ])
}

fn cyndy_post(
  from content: Element(a),
  with variables: Dict(String, String),
  store store: clientstore.ClientStore,
) -> Element(a) {
  console.info("Variables: \n\t" <> string.inspect(variables))
  let menus = clientstore.pull_menus(store)
  html.div([attribute.id("content"), attribute.class("w-full mb-2")], [
    html.span([], [
      html.div(
        [
          attribute.class(
            "grid grid-cols-5 grid-rows-12 gap-2 w-screen h-screen",
          ),
        ],
        [
          html.div(
            [
              attribute.class(
                "col-span-4 row-span-11 col-start-2 row-start-2 overflow-auto min-h-full relative m-0",
              ),
            ],
            [content],
          ),
          html.div([attribute.class("col-span-5 p-0 m-0")], [
            html.text("Menu 1 goes here"),
          ]),
          html.div(
            [attribute.class("row-span-8 col-start-1 row-start-2 min-h-full")],
            [html.text("Post-meta (if any) goes here")],
          ),
        ],
      ),
    ]),
  ])
}

fn cyndy_menu_1(from content: Dict(Int, List(#(String, String)))) {
  case dict.get(content, 1) {
    Error(_) -> []
    Ok(dookie) -> {
      list.map(dookie, fn(a) { html.a([attribute.href(a.1)], [html.text(a.0)]) })
    }
  }
}

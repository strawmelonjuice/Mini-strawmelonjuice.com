import cynthia_websites_mini_client/datamanagement/clientstore
import gleam/dict.{type Dict}
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
    html.span([], [content, html.br([])]),
  ])
}

fn cyndy_post(
  from content: Element(a),
  with variables: Dict(String, String),
  store store: clientstore.ClientStore,
) -> Element(a) {
  todo
}

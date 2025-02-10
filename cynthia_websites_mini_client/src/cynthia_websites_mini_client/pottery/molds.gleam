import cynthia_websites_mini_client/datamanagement/clientstore
import gleam/dict.{type Dict}
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html

/// Molds is the name we use for templating here.
pub fn into(
  layout layout: String,
  for theme_type: String,
) -> fn(Dict(String, String)) -> element.Element(a) {
  let is_post_not_page = case theme_type {
    "post" -> True
    "page" -> False
    _ -> panic as "Unknown content type"
  }
  case layout {
    "cindy" -> {
      case is_post_not_page {
        False -> cyndy_page
        True -> cyndy_post
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
fn cyndy_page(d: Dict(String, String)) -> element.Element(a) {
  let assert Ok(content) = dict.get(d, "content")
  html.div([attribute.id("content")], [html.span([], [html.text(content)])])
}

fn cyndy_post(d: Dict(String, String)) -> element.Element(a) {
  todo
}

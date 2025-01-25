import gleam/result
import lustre/element as le_element
import plinth/browser/document
import plinth/browser/element

pub fn push(title: String, body: le_element.Element(a)) {
  use title_element <- result.then(
    document.query_selector("title")
    |> result.replace_error("No title element found"),
  )

  title_element |> element.set_inner_text(title)

  let new_body = le_element.to_string(body)
  use body_element <- result.then(
    document.query_selector("div#viewable")
    |> result.replace_error("No viewable element found"),
  )

  body_element
  |> element.set_inner_html(new_body)
  Ok(Nil)
}

/// Get the color scheme of the user's system (media query)
@external(javascript, "./dom.ts", "get_color_scheme")
pub fn get_color_scheme() -> String

/// Set the data attribute of an element
@external(javascript, "./dom.ts", "set_data")
pub fn set_data(element: element.Element, key: String, value: String) -> Nil

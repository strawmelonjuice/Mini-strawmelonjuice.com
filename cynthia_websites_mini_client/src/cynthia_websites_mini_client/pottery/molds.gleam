// Imports
import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/dom
import gleam/dict.{type Dict}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import plinth/browser/document as plinth_document
import plinth/browser/element as plinth_element
import plinth/javascript/console

// Imports from layout modules
import cynthia_websites_mini_client/pottery/molds/cindy_simple

/// Molds is the name we use for templating here.
pub fn into(
  layout layout: String,
  for theme_type: String,
  store store: clientstore.ClientStore,
  is priority: Bool,
) -> fn(Element(a), Dict(String, String)) -> element.Element(a) {
  let is_post = case theme_type {
    "post" -> True
    "page" -> False
    _ -> panic as "Unknown content type"
  }
  case layout {
    // Add your layout handler here!
    "cindy" | "cindy-simple" -> {
      // Cindy shows a different layout for pages and posts.
      // If you want to do same kind of split, you can use the `is_post` variable in a case statement like below.
      //
      // For other types of splits, you can split within the function, where you have access to the content and metadata.
      case is_post {
        False -> fn(content: Element(a), metadata: Dict(String, String)) -> Element(
          a,
        ) {
          cindy_simple.page_layout(content, metadata, store, priority)
        }
        True -> fn(content: Element(a), metadata: Dict(String, String)) -> Element(
          a,
        ) {
          cindy_simple.post_layout(content, metadata, store, priority)
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
        // Add your layout menu handler here!
        "cindy" -> {
          let temp_menu =
            res
            // This is a call to the layout function that returns the menu!
            |> cindy_simple.menu_1()
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

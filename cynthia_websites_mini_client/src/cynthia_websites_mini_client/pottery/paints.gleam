import cynthia_websites_mini_client/datamanagement.{type ClientStore}
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_shared/ui/themes_generated
import gleam/io
import gleam/list
import gleam/result

pub fn get_sytheme(store: ClientStore) {
  let theme = case dom.get_color_scheme() {
    "light" -> {
      datamanagement.pull_from_global_config_table(store, "theme")
      |> result.map_error(fn(_) {
        io.print_error("Error getting light color scheme from database")
      })
      |> result.unwrap("autumn")
    }
    "dark" -> {
      datamanagement.pull_from_global_config_table(store, "theme_dark")
      |> result.map_error(fn(_) {
        io.print_error("Error getting dark color scheme from database")
      })
      |> result.unwrap("coffee")
    }
    _ -> {
      panic
    }
  }

  themes_generated.themes
  |> list.find(fn(th) { th.name == theme })
}

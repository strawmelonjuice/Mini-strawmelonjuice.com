import cynthia_websites_mini_client/datamanagement/clientstore.{type ClientStore}
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/ui/themes_generated
import gleam/io
import gleam/list
import gleam/result
import plinth/javascript/console

pub fn get_sytheme(store: ClientStore) {
  let theme = case dom.get_color_scheme() {
    "light" -> {
      clientstore.pull_from_global_config_table(store, "theme")
      |> result.map_error(fn(_) {
        console.error("Error getting light color scheme from database")
      })
      |> result.unwrap(
        configtype.default_shared_cynthia_config_global_only.global_theme,
      )
    }
    "dark" -> {
      clientstore.pull_from_global_config_table(store, "theme_dark")
      |> result.map_error(fn(_) {
        console.error("Error getting dark color scheme from database")
      })
      |> result.unwrap(
        configtype.default_shared_cynthia_config_global_only.global_theme_dark,
      )
    }
    _ -> {
      panic
    }
  }

  themes_generated.themes
  |> list.find(fn(th) { th.name == theme })
}

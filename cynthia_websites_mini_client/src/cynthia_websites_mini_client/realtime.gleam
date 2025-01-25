import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/dom
import gleam/io
import gleam/result
import gleam/string
import plinth/browser/document

pub fn main() {
  update_styles()
}

fn update_styles() {
  case dom.get_color_scheme() {
    "light" -> {
      datamanagement.pull_from_global_config_table("color_scheme")
      |> result.unwrap("autumn")
      |> dom.set_data(document.body(), "theme", _)
    }
    "dark" -> {
      datamanagement.pull_from_global_config_table("color_scheme_dark")
      |> result.unwrap("coffee")
      |> dom.set_data(document.body(), "theme", _)
    }
    _ -> {
      Nil
    }
  }
}

import bungibindies/bun/http/serve/request.{type Request}
import bungibindies/bun/http/serve/response
import bungibindies/bun/sqlite
import cynthia_websites_mini_server/database
import cynthia_websites_mini_server/database/content_data
import gleam/javascript/array
import gleam/javascript/promise
import gleam/json
import gleam/result
import gleam/uri

pub fn handle_request(req: Request, db: sqlite.Database) {
  let assert Ok(req_uri) = req |> request.url() |> uri.parse()
  let path = req_uri.path
  case path {
    "/fetch/minimal-content-list" -> {
      promise.resolve(
        response.new()
        |> response.set_body(
          content_data.get_minimal_content_list(db)
          |> content_data.minimal_json_encoder(),
        )
        |> response.set_headers(
          [#("Content-Type", "application/json; charset=utf-8")]
          |> array.from_list(),
        ),
      )
    }
    "/fetch/global-site-config" -> {
      promise.resolve(send_global_site_config(db))
    }
    _ -> {
      promise.resolve(
        response.new()
        |> response.set_body("{ \"message\": \"Hello, world!\" }")
        |> response.set_status(303)
        |> response.set_headers(
          [#("Location", "/404")]
          |> array.from_list(),
        ),
      )
    }
  }
}

fn send_global_site_config(db: sqlite.Database) {
  case database.get__entire_global_config(db) {
    Ok(data) -> {
      response.new()
      |> response.set_body({
        json.object([
          #("site_name", json.string(data.global_site_name)),
          #("site_colour", json.string(data.global_colour)),
          #("site_description", json.string(data.global_site_description)),
          #("global_theme", json.string(data.global_theme)),
          #("global_theme_dark", json.string(data.global_theme_dark)),
          #("global_layout", json.string(data.global_layout)),
        ])
        |> json.to_string()
      })
      |> response.set_headers(
        [#("Content-Type", "application/json; charset=utf-8")]
        |> array.from_list(),
      )
    }
    Error(_) -> {
      response.new()
      |> response.set_body(
        "{ \"message\": \"Error fetching global site config\" }",
      )
      |> response.set_status(500)
      |> response.set_headers(
        [#("Content-Type", "application/json; charset=utf-8")]
        |> array.from_list(),
      )
    }
  }
}

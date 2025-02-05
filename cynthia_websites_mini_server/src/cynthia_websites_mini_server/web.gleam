import bungibindies/bun/http/serve/request.{type Request}
import bungibindies/bun/http/serve/response
import bungibindies/bun/sqlite
import cynthia_websites_mini_server/database
import cynthia_websites_mini_server/database/content_data
import cynthia_websites_mini_server/static_routes
import gleam/javascript/array
import gleam/javascript/map
import gleam/javascript/promise
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri
import gleamy_lights/console
import gleamy_lights/premixed

pub fn handle_request(req: Request, db: sqlite.Database) {
  let assert Ok(req_uri) = req |> request.url() |> uri.parse()
  let path = req_uri.path
  let assert Some(dynastatic) = static_routes.static_routes()
  case path {
    "/" -> {
      console.log(
        premixed.text_ok_green("[ 200 ]\t")
        <> premixed.text_blue("/")
        <> " "
        <> premixed.text_cyan("(client-side is now loading a web page)"),
      )
      dynastatic
      |> map.get("/index.html")
      |> result.unwrap(response.new())
      |> promise.resolve()
    }
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
    f -> {
      console.error(
        premixed.text_error_red("[ 404 ] ") <> premixed.text_blue(f),
      )
      dynastatic
      |> map.get("/404")
      |> result.unwrap(response.new())
      |> promise.resolve()
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

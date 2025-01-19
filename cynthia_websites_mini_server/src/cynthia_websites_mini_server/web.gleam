import bungibindies/bun/http/serve/request.{type Request}
import bungibindies/bun/http/serve/response
import cynthia_websites_mini_server/config
import gleam/javascript/array
import gleam/javascript/promise
import gleam/uri

pub fn handle_request(req: Request) {
  let assert Ok(req_uri) = req |> request.url() |> uri.parse()
  let path = req_uri.path
  case path {
    "/get" -> {
      let _ = config.load()
      promise.resolve(
        response.new()
        |> response.set_body("{ \"message\": \"Hello, world!\" }")
        |> response.set_headers(
          [#("Content-Type", "application/json; charset=utf-8")]
          |> array.from_list(),
        ),
      )
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

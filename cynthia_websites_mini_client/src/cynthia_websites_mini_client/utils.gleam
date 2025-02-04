import gleam/http
import gleam/http/request.{type Request}
import gleam/string
import plinth/browser/element.{type Element}
import plinth/browser/window

pub fn phone_home() -> Request(String) {
  request.new()
  |> request.set_scheme({
    let origin = window.origin()
    case origin {
      "http://" <> _ -> http.Http
      "https://" <> _ -> http.Https
      _ -> http.Https
    }
  })
  |> request.set_host(get_window_host())
}

@external(javascript, "./utils_ffi.ts", "getWindowHost")
pub fn get_window_host() -> String

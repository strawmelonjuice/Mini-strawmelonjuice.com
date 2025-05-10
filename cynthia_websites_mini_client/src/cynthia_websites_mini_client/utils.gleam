import gleam/http
import gleam/http/request.{type Request}
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

pub fn phone_home_url() -> String {
  let origin = window.origin()
  let host = get_window_host()
  case origin {
    "http://" <> _ -> "http://" <> host
    "https://" <> _ -> "https://" <> host
    _ -> "https://" <> host
  }
  <> window.pathname()
}

@external(javascript, "./utils_ffi.ts", "getWindowHost")
pub fn get_window_host() -> String

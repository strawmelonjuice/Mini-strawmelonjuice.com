import bungibindies/bun
import bungibindies/bun/bunfile.{type BunFile}
import bungibindies/bun/http/serve/request.{type Request}
import bungibindies/bun/http/serve/response
import cynthia_websites_mini_server/config
import cynthia_websites_mini_server/mutable_model_type
import cynthia_websites_mini_server/static_routes
import cynthia_websites_mini_shared/configtype
import gleam/dict
import gleam/javascript/array
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import gleamy_lights/console
import gleamy_lights/premixed
import javascript/mutable_reference
import plinth/node/process
import simplifile

pub fn handle_request(
  req: Request,
  mutable_model: mutable_model_type.MutableModel,
) {
  let assert Ok(req_uri) = req |> request.url() |> uri.parse()
    as "Request URI should be valid"
  let path = req_uri.path
  let assert Some(dynastatic) = static_routes.static_routes(mutable_model)
    as "Static routes should always be valid."
  case path {
    "/" -> {
      console.log(
        premixed.text_ok_green("[ 200 ]\t")
        <> "(GET)\t"
        <> premixed.text_lightblue("/")
        <> " "
        <> premixed.text_cyan(
          "\t(this means client-side will now start loading a web page)",
        ),
      )
      dynastatic
      |> dict.get("/index.html")
      |> result.unwrap(response.new())
      |> promise.resolve()
    }
    "/site.json" -> {
      let model = mutable_reference.get(mutable_model)
      case model.cached_response {
        Some(res_string) -> {
          // Cache hit! Return the cached response string so that it can be used in the response body
          res_string
        }
        None -> {
          // If there is no cached response, load the complete data from the config file
          // and encode it as JSON
          let complete_data = config.load()
          let complete_data_json =
            complete_data |> configtype.encode_complete_data
          let res_string = complete_data_json |> json.to_string
          // And add it to the model as cache for future requests
          mutable_reference.update(mutable_model, fn(model) {
            mutable_model_type.MutableModelContent(
              ..model,
              cached_response: Some({ res_string }),
            )
          })
          // Now return the response string so that it can be used in the response body
          res_string
        }
      }
      |> response.set_body(response.new(), _)
      |> response.set_headers(
        [#("Content-Type", "text/json; charset=utf-8")]
        |> array.from_list(),
      )
      |> response.set_status(200)
      |> promise.resolve
    }
    "/assets/" <> f -> {
      let filepath = process.cwd() <> "/assets/" <> f
      case simplifile.is_file(filepath) {
        Ok(True) -> {
          console.log(
            premixed.text_ok_green("[ 200 ]\t")
            <> "(GET)\t"
            <> premixed.text_lightblue("/assets/")
            <> premixed.text_cyan(f),
          )
          filepath
          |> bun.file()
          |> answer_bunrequest_with_file()
        }
        _ -> {
          console.error(
            premixed.text_error_red("[ 404 ] ")
            <> "(GET)\t"
            <> premixed.text_lightblue("/assets/")
            <> premixed.text_cyan(f),
          )
          dynastatic
          |> dict.get("/404")
          |> result.unwrap(response.new())
          |> promise.resolve()
        }
      }
    }
    f -> {
      console.error(
        premixed.text_error_red("[ 404 ] ")
        <> "("
        <> req |> request.method
        <> ")\t"
        <> premixed.text_lightblue(f),
      )
      dynastatic
      |> dict.get("/404")
      |> result.unwrap(response.new())
      |> promise.resolve()
    }
  }
}

@external(javascript, "./request_ffi.ts", "get_request_body")
pub fn get_request_body(req: Request) -> Promise(BitArray)

@external(javascript, "./request_ffi.ts", "get_request_body_as_text")
pub fn get_request_body_as_text(req: Request) -> Promise(String)

@external(javascript, "./request_ffi.ts", "answer_bunrequest_with_file")
pub fn answer_bunrequest_with_file(file: BunFile) -> Promise(response.Response)

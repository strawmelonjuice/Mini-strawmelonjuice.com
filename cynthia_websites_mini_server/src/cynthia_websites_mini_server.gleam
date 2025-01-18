import bungibindies
import bungibindies/bun
import bungibindies/bun/http/serve.{ServeOptions}
import bungibindies/bun/http/serve/request.{type Request}
import bungibindies/bun/http/serve/response
import gleam/io
import gleam/javascript/array
import gleam/javascript/promise
import gleam/option.{None, Some}
import gleamy_lights/premixed
import plinth/node/process

pub fn main() {
  case bungibindies.runs_in_bun() {
    Ok(_) -> Nil
    Error(_) -> {
      io.println(premixed.text_red(
        "Error: Cynthia mini needs to run in Bun! Try installing and running it with Bun instead.",
      ))
      process.exit(1)
    }
  }
  io.println(
    premixed.text_green("Hello from cynthia_websites_mini_server! ")
    <> "Running in "
    <> premixed.text_bright_orange(process.cwd())
    <> "!",
  )
  bun.serve(ServeOptions(
    development: Some(True),
    hostname: None,
    port: None,
    static_served: None,
    handler: handle_request(_, "Hello from cynthia_websites_mini_server!"),
    id: None,
    reuse_port: None,
  ))
}

fn handle_request(req: Request, answer: String) {
  io.println(
    premixed.bg_ok_green(premixed.text_black("200"))
    <> " ==> "
    <> req |> request.url |> premixed.text_bright_orange(),
  )
  promise.resolve(
    response.new()
    |> response.set_body(answer)
    |> response.set_headers(
      [#("Content-Type", "text/html; charset=utf-8")]
      |> array.from_list(),
    ),
  )
}

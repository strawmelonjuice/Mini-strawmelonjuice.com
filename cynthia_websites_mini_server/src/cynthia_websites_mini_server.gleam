import bungibindies
import bungibindies/bun
import bungibindies/bun/http/serve.{ServeOptions}
import cynthia_websites_mini_server/config
import cynthia_websites_mini_server/database
import cynthia_websites_mini_server/static_routes
import cynthia_websites_mini_server/web
import gleam/io
import gleam/option.{None, Some}
import gleamy_lights/premixed
import plinth/node/process

pub fn main() {
  case bungibindies.runs_in_bun() {
    Ok(_) -> Nil
    Error(_) -> {
      io.println(premixed.text_red(
        "Error: Cynthia Mini needs to run in Bun! Try installing and running it with Bun instead.",
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
  let #(db, conf) = config.load()
  io.println("Starting server...")
  let assert Ok(_) =
    bun.serve(ServeOptions(
      development: Some(True),
      hostname: None,
      port: None,
      static_served: static_routes.static_routes(),
      handler: web.handle_request,
      id: None,
      reuse_port: None,
    ))
}

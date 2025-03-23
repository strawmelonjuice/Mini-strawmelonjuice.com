import bungibindies
import bungibindies/bun
import bungibindies/bun/http/serve.{ServeOptions}
import cynthia_websites_mini_server/config
import cynthia_websites_mini_server/database
import cynthia_websites_mini_server/static_routes
import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_server/web
import cynthia_websites_mini_server/web/comments
import cynthia_websites_mini_shared/configtype
import gleam/bit_array
import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/option.{None, Some}
import gleamy_lights/console
import gleamy_lights/premixed
import plinth/javascript/global
import plinth/node/process
import simplifile

pub fn main() {
  case bungibindies.runs_in_bun() {
    Ok(_) -> Nil
    Error(_) -> {
      console.log(premixed.text_red(
        "Error: Cynthia Mini needs to run in Bun! Try installing and running it with Bun instead.",
      ))
      process.exit(1)
    }
  }
  console.log(
    premixed.text_green("Hello from cynthia_websites_mini_server! ")
    <> "Running in "
    <> premixed.text_bright_orange(process.cwd())
    <> "!",
  )
  let #(db, conf) = config.load()
  {
    let wasmfile = process.cwd() <> "/assets/cynthia-mini/sql-wasm.wasm"
    case files.file_exist(wasmfile) {
      True -> Nil
      False -> {
        {
          console.log("Downloading important assets before starting server...")
          let wasmurl =
            "https://cdn.jsdelivr.net/npm/sql.js@1.13.0/dist/sql-wasm.wasm"
          let assert Ok(_) =
            simplifile.create_directory_all(
              process.cwd() <> "/assets/cynthia-mini/",
            )
          let assert Ok(req) = request.to(wasmurl)
          use resp <- promise.await(fetch.send(req))
          let resp = case resp {
            Ok(r) -> r
            Error(_) -> {
              console.error(
                "Error: Could not fetch "
                <> premixed.bg_bright_yellow(wasmurl)
                <> " from the internet."
                |> premixed.text_error_red(),
              )
              process.exit(1)
              panic
            }
          }
          use resp <- promise.await(fetch.read_bytes_body(resp))
          let resp = case resp {
            Ok(r) -> r
            Error(_) -> {
              console.error(
                "Error: Could not fetch "
                <> premixed.bg_bright_yellow(wasmurl)
                <> " from the internet."
                |> premixed.text_error_red(),
              )
              process.exit(1)
              panic
            }
          }
          case simplifile.write_bits(wasmfile, resp.body) {
            Ok(_) -> Nil
            Error(_) -> {
              console.error(
                "Error: Could not write "
                <> premixed.bg_bright_yellow(wasmfile)
                <> "to disk."
                |> premixed.text_error_red(),
              )
              process.exit(1)
              Nil
            }
          }
          promise.resolve(Ok(Nil))
        }
        Nil
      }
    }
    case files.file_exist(process.cwd() <> "/assets/cynthia-mini/README.md") {
      True -> Nil
      False -> {
        let assert Ok(_) =
          simplifile.write(
            process.cwd() <> "/assets/cynthia-mini/README.md",
            "# What does this folder do?\n\r\n\rThis folder holds a few files Cynthia Mini serves to the browser to make sure everything works alright.\n\r\n\rThese are usually checked and downloaded if necessary only during start of the server,\n\rso try not to touch them! If you believe one of the files in here might be faulty, delete it, and restart the server.\n\r\n\rHave a nice day! :)",
          )
        Nil
      }
    }
  }
  console.log("Starting server...")
  let assert Ok(_) =
    bun.serve(ServeOptions(
      development: Some(True),
      hostname: conf.server_host,
      port: conf.server_port,
      static_served: static_routes.static_routes(db),
      handler: web.handle_request(_, db),
      id: None,
      reuse_port: None,
    ))
  console.log("Server started!")
  global.set_interval(60_000, fn() {
    // This function is called every minute
    let co =
      configtype.SharedCynthiaConfigGlobalOnly(
        global_theme: conf.global_theme,
        global_theme_dark: conf.global_theme_dark,
        global_colour: conf.global_colour,
        global_site_name: conf.global_site_name,
        global_site_description: conf.global_site_description,
        server_port: conf.server_port,
        server_host: conf.server_host,
        posts_comments: conf.posts_comments,
      )
    config.update_content_in_db(db, co)
    Nil
  })
  global.set_interval(40_000, fn() {
    comments.periodic_write_to_file(db)
    Nil
  })
}

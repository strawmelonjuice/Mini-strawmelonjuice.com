import bungibindies/bun/http/serve/response
import cynthia_websites_mini_server/utils/files.{client_css, client_js}
import cynthia_websites_mini_shared/ui
import gleam/javascript/array
import gleam/javascript/map
import gleam/option.{Some}

pub fn static_routes() {
  map.new()
  |> map.set("/index.html", main())
  |> map.set("/404", notfound())
  |> Some
}

fn main() {
  response.new()
  |> response.set_body("<!DOCTYPE html>
  <html lang='en'>
  <head>
  <title>cynthia_websites_mini_server</title>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <script type='module'>
  " <> client_js() <> "
  </script>
  <style>" <> client_css() <> "</style>
  </head>
  <body>
    <div id='viewable' class='bg-base-100 w-screen h-screen'>
    </div>
   " <> ui.footer <> "
  </body>
  </html>
")
  |> response.set_headers(
    [#("Content-Type", "text/html; charset=utf-8")]
    |> array.from_list(),
  )
  |> response.set_status(200)
}

fn notfound() {
  response.new()
  |> response.set_body("<!DOCTYPE html>
  <html lang='en'>
  <head>
  <title>cynthia_websites_mini_server</title>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <script type='module'>
  " <> client_js() <> "
  </script>
  <style>" <> client_css() <> "</style>
  </head>
  <body data-404='true' class='bg-base-100 w-[100VW] h-[100VH]'>
    " <> ui.notfoundbody() <> "
    </body>
      </html>
")
  |> response.set_headers(
    [#("Content-Type", "text/html; charset=utf-8")]
    |> array.from_list(),
  )
  |> response.set_status(404)
}

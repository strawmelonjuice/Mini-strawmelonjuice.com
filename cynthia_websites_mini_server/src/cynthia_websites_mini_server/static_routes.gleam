import bungibindies/bun/http/serve/response
import cynthia_websites_mini_client as client
import cynthia_websites_mini_shared/ui
import gleam/javascript/array
import gleam/javascript/map
import gleam/option.{Some}

pub fn static_routes() {
  map.new()
  |> map.set("/", main())
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
  " <> client.js() <> "
  </script>
  <style>" <> client.css() <> "</style>
  </head>
  <body>
    <div id='viewable'>
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

  <style>" <> client.css() <> "</style>
  </head>
  <body>
    <div
class =        'absolute right-[40VW] left-[40VW] bottom-[40VH] top-[40VH] w-fit h-fit',>
<div class='card bg-neutral text-neutral-content w-96'>
  <div class='card-body items-center text-center'>
    <h2 class='card-title'>404!</h2>
    <p>Uh-oh, that page cannot be found.</p>
    <div class='card-actions justify-end'>
      <button class='btn btn-primary' onclick='javascript:window.location.replace(\"/\")'>Go home</button>
      <button class='btn btn-ghost' onclick='javascript:window.history.back(1)'>Go back</button>
    </div>
  </div>
</div>
    </div>   
    " <> ui.footer <> "
  </body>
  </html>
")
  |> response.set_headers(
    [#("Content-Type", "text/html; charset=utf-8")]
    |> array.from_list(),
  )
  |> response.set_status(404)
}

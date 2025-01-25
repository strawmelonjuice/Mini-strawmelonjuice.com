import cynthia_websites_mini_client/datamanagement/database
import cynthia_websites_mini_client/pottery/ceramics
import cynthia_websites_mini_client/realtime
import gleam/io
import gleam/string
import plinth/browser/document
import plinth/javascript/global

pub fn main() {
  ceramics.loading_screen()
  io.println(string.inspect(document.body()))
  // Initialise database
  // io.println("DB: " <> string.inspect(db))
  global.set_interval(200, realtime.main)
  todo as "Nothing after the loading screen yet!"
}

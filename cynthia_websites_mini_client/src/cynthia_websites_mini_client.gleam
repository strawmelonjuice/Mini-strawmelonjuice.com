import cynthia_websites_mini_client/datamanagement/database
import cynthia_websites_mini_client/pottery/ceramics
import cynthia_websites_mini_client/realtime
import gleam/io
import gleam/string
import plinth/browser/document

pub fn main() {
  ceramics.loading_screen()
  io.println(string.inspect(document.body()))
  // Initialise database
  let db = database.init()
  let _ = realtime.main(db)
  todo as "Nothing after the loading screen yet!"
}

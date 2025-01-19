import cynthia_websites_mini_client/datamanagement/database

import cynthia_websites_mini_client/pottery/ceramics
import gleam/io
import gleam/string

pub fn main() {
  ceramics.loading_screen()
  let db = database.init()
  // Initialise database
  io.println("DB: " <> string.inspect(db))
  todo as "Nothing after the loading screen yet!"
}

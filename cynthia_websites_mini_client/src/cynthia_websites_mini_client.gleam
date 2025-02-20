import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/pottery/ceramics
import cynthia_websites_mini_client/realtime
import gleam/io
import gleam/result
import plinth/browser/window

pub fn main() {
  ceramics.loading_screen()
  // Initialise database
  let clientstore = datamanagement.init()
  let _ = realtime.main(clientstore)
  datamanagement.update_content_queue(clientstore)
  // Check current page and priotise loading of current content
  priority_loader()
}

fn hash_getter() -> String {
  // Load content based on current page
  // Check if content is already loaded
  // If not, load content
  // If content is loaded, check if content is up to date
  // If not, update content
  // If content is up to date, do nothing
  case
    window.get_hash()
    |> result.unwrap("")
  {
    "" -> {
      // Set hash  to "/" if no hash is present
      dom.set_hash("/")
      priority_loader()
    }
    current_hash -> {
      current_hash
    }
  }
}

fn priority_loader() {
  let current_hash =
    hash_getter()
    |> io.debug()
  todo as "Priority loader not yet implemented"
}

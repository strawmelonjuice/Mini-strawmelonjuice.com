import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/pottery
import cynthia_websites_mini_client/pottery/ceramics
import cynthia_websites_mini_client/realtime
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_shared/configtype
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/javascript/promise
import gleam/result
import gleam/string
import plinth/browser/window

pub fn main() {
  ceramics.loading_screen()
  // Initialise database
  use clientstore <- datamanagement.init()
  let _ = realtime.main(clientstore)
  datamanagement.update_content_queue(clientstore)
  // Check current page and priotise loading of current content
  priority_loader(clientstore)
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
      hash_getter()
    }
    current_hash -> {
      current_hash
    }
  }
}

fn priority_loader(store: clientstore.ClientStore) -> Nil {
  let current_hash = hash_getter()
  {
    let res =
      utils.phone_home()
      |> request.set_method(http.Post)
      |> request.set_path("/fetch/content/priority/")
      |> request.set_body(current_hash)
      |> fetch.send()
      |> promise.try_await(fetch.read_json_body)
    use res <- promise.await(res)
    {
      use res <- result.try(result.replace_error(res, Nil))
      let #(data, innercontent) = case
        decode.run(res.body, datamanagement.collected_content_decoder())
      {
        Error(w) -> {
          let s = "Failed to decode content: " <> string.inspect(w)
          panic as s
        }
        Ok(d) -> d
      }
      let title = case data {
        configtype.ContentsPage(content) -> content.title
        configtype.ContentsPost(content) -> content.title
      }
      let assert Ok(_) =
        dom.push(title, pottery.render_content(store, data, innercontent, True))
      Ok(Nil)
    }
    |> promise.resolve
  }
  Nil
}

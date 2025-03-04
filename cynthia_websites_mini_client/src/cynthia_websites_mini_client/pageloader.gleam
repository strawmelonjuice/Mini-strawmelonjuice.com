import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/errors
import cynthia_websites_mini_client/pottery
import cynthia_websites_mini_client/pottery/molds
import cynthia_websites_mini_client/pottery/oven
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/ui
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element/html
import plinth/browser/window
import plinth/javascript/console

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

pub fn priority(store: clientstore.ClientStore) -> Nil {
  let current_hash = hash_getter()
  set_lasthash(store, current_hash)
  {
    let req =
      utils.phone_home()
      |> request.set_method(http.Post)
      |> request.set_path("/fetch/content/priority/")
      |> request.set_body(current_hash)
    use resp <- promise.try_await(fetch.send(req))
    let ft = fn(
      resp: response.Response(fetch.FetchBody),
      continue: fn(response.Response(fetch.FetchBody)) -> a,
    ) -> a {
      case resp.status {
        200 -> continue(resp)
        404 -> {
          set_to_404(ui.notfoundbody())
          panic
        }
        _ -> {
          oven.error("Failed to fetch content: " <> string.inspect(resp))
          panic
        }
      }
    }
    use resp <- ft(resp)
    use res <- promise.try_await(fetch.read_json_body(resp))
    {
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

/// Load the content for the current page, checking the the database for existing content first, and updating if necessary. This should only be contacting the server if the content is not already downloaded.
pub fn now(store: clientstore.ClientStore) -> Result(Nil, errors.AnError) {
  console.info("Hash change detected, refreshing content")
  let current_hash = hash_getter()
  console.log("Current hash: " <> current_hash)
  case
    datamanagement.fetch_content_from_clientstore_by_permalink(
      store,
      current_hash,
    )
  {
    Ok(content) -> {
      console.info("Content already downloaded, loading into DOM")
      let assert Ok(_) =
        dom.push(
          content.meta_title,
          html.div(
            [attribute.attribute("dangerous-unescaped-html", content.html)],
            [],
          ),
        )
      molds.retroactive_menu_update(store)
      Ok(Nil)
    }
    Error(_) -> {
      console.info("Content not downloaded, fetching from server")
      priority(store)
      Ok(Nil)
    }
  }
}

@external(javascript, "./dom.ts", "set_to_404")
fn set_to_404(body: String) -> Nil

// @external(javascript, "./datamanagement_ffi.ts", "set_lasthash")
// fn set_lasthash(store: clientstore.ClientStore, hash: String) -> Nil
const set_lasthash = datamanagement.update_lasthash

import cynthia_websites_mini_client/utils
import cynthia_websites_mini_shared/configtype.{
  type SharedCynthiaConfigGlobalOnly, default_shared_cynthia_config_global_only,
}
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/javascript/array.{type Array}
import gleam/javascript/promise
import gleam/result

pub fn pull_from_global_config_table(
  store: ClientStore,
  item what: String,
) -> Result(String, Nil) {
  iget(store, what) |> array.get(0)
}

@external(javascript, "./datamanagement_ffi.ts", "get_config_item")
fn iget(store: ClientStore, what: String) -> Array(String)

pub fn populate_global_config_table(store: ClientStore) {
  let res =
    utils.phone_home()
    |> request.set_method(http.Get)
    |> request.set_path("/fetch/global-site-config")
    |> fetch.send()
    |> promise.try_await(fetch.read_json_body)
  use res <- promise.await(res)
  {
    use res <- result.try(result.replace_error(res, Nil))
    let data =
      decode.run(
        res.body,
        configtype.shared_cynthia_config_global_only_decoder(),
      )
    use data <- result.try(result.replace_error(data, Nil))
    populate_global_config(store, data)
    Ok(Nil)
  }
  |> promise.resolve
}

@external(javascript, "./datamanagement_ffi.ts", "populate_global_config")
fn populate_global_config(
  store: ClientStore,
  conf: SharedCynthiaConfigGlobalOnly,
) -> Nil

pub fn init() -> ClientStore {
  i_init(default_shared_cynthia_config_global_only)
}

@external(javascript, "./datamanagement_ffi.ts", "initialise")
fn i_init(p: SharedCynthiaConfigGlobalOnly) -> ClientStore

/// This is a temporary solution replacing an in-browser-database for the time being.
pub type ClientStore

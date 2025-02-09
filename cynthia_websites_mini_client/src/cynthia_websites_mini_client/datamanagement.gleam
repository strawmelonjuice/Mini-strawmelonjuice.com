import cynthia_websites_mini_client/datamanagement/clientstore.{
  type ClientStore as Store, iget, next_in_content_queue,
}

import cynthia_websites_mini_client/pottery
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_shared/configtype.{
  type SharedCynthiaConfigGlobalOnly, default_shared_cynthia_config_global_only,
}
import cynthia_websites_mini_shared/contenttypes
import gleam/dynamic/decode
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/javascript/array.{type Array}
import gleam/javascript/promise
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

pub fn pull_from_global_config_table(
  store: ClientStore,
  item what: String,
) -> Result(String, Nil) {
  iget(store, what) |> array.get(0)
}

pub fn update_content_queue(store: ClientStore) {
  let res =
    utils.phone_home()
    |> request.set_method(http.Get)
    |> request.set_path("/fetch/minimal-content-list")
    |> fetch.send()
    |> promise.try_await(fetch.read_json_body)
  use res <- promise.await(res)
  {
    use res <- result.try(result.replace_error(res, Nil))

    decode.run(res.body, decode.list(contenttypes.minimal_aliased_decoder()))
    |> result.unwrap([])
    |> list.each(fn(item) { add_to_content_queue(store, item) })
    Ok(Nil)
  }
  |> promise.resolve
}

@external(javascript, "./datamanagement_ffi.ts", "add_to_content_queue")
fn add_to_content_queue(store: ClientStore, data: contenttypes.Minimal) -> Nil

pub fn render_next_of_content_queue(store: ClientStore) {
  use next <- next_in_content_queue(store)
  {
    let res =
      utils.phone_home()
      |> request.set_method(http.Post)
      |> request.set_path("/fetch/content/")
      |> request.set_body(next.original_filename)
      |> fetch.send()
      |> promise.try_await(fetch.read_json_body)
    use res <- promise.await(res)
    {
      use res <- result.try(result.replace_error(res, Nil))
      let assert Ok(#(data, innercontent)) =
        decode.run(res.body, collected_content_decoder())
      let s = pottery.render_content(store, data, innercontent)
      Ok(Nil)
    }
    |> promise.resolve
  }
  Nil
}

/// Now, this is where I am fixing the fact I fucked up the content types in `configtypes`, should've made them be one type with multiple variants. -- And in `contenttype`, obviously.
/// 
/// What is done here? This is a huge type containing all the fields in both, but having the specific ones be `Option`al. This is a temporary solution, and I will fix it later. Hopefully.
type CollectedContent {
  CollectedContent(
    // Common to all content
    filename: String,
    title: String,
    description: String,
    layout: String,
    permalink: String,
    // Unique to unspecified content
    kind: String,
    inner: String,
    // Unique to page
    page: Option(configtype.PagePageData),
    // Unique to post
    post: Option(configtype.PostMetaData),
  )
}

fn collected_content_decoder() -> decode.Decoder(#(configtype.Contents, String)) {
  use inner <- decode.field("inner", decode.string)
  use filename <- decode.field("filename", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- decode.field("layout", decode.string)
  use permalink <- decode.field("permalink", decode.string)
  use kind <- decode.field("kind", decode.string)
  use page <- decode.field(
    "page",
    decode.optional(fn() -> decode.Decoder(configtype.PagePageData) {
      use menus <- decode.field("menus", decode.list(decode.int))
      decode.success(configtype.ContentsPagePageData(menus:))
    }()),
  )
  use post <- decode.field(
    "post",
    decode.optional(fn() -> decode.Decoder(configtype.PostMetaData) {
      use date_posted <- decode.field("date-posted", decode.string)
      use date_updated <- decode.field("date-updated", decode.string)
      use category <- decode.field("category", decode.string)
      use tags <- decode.field("tags", decode.list(decode.string))
      decode.success(configtype.PostMetaData(
        date_posted:,
        date_updated:,
        category:,
        tags:,
      ))
    }()),
  )
  case kind {
    "page" -> {
      let assert Some(page) = page
      decode.success(#(
        configtype.ContentsPage(configtype.Page(
          filename:,
          title:,
          description:,
          layout:,
          permalink:,
          page:,
        )),
        inner,
      ))
    }
    "post" -> {
      let assert Some(post) = post
      decode.success(#(
        configtype.ContentsPost(configtype.Post(
          filename:,
          title:,
          description:,
          layout:,
          permalink:,
          post:,
        )),
        inner,
      ))
    }
    _ -> panic as "Unknown kind of content"
  }
}

pub type ClientStore =
  Store

pub const populate_global_config = clientstore.populate_global_config

pub const populate_global_config_table = clientstore.populate_global_config_table

pub const init = clientstore.init

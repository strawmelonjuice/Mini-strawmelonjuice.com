import bungibindies/bun/http/serve/request.{type Request}
import bungibindies/bun/http/serve/response
import bungibindies/bun/sqlite
import cynthia_websites_mini_server/database
import cynthia_websites_mini_server/database/content_data
import cynthia_websites_mini_server/static_routes
import cynthia_websites_mini_shared/configtype.{ContentsPage, ContentsPost}
import gleam/bit_array
import gleam/bool
import gleam/javascript/array
import gleam/javascript/map
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import gleamy_lights/console
import gleamy_lights/premixed

pub fn handle_request(req: Request, db: sqlite.Database) {
  let assert Ok(req_uri) = req |> request.url() |> uri.parse()
  let path = req_uri.path
  let assert Some(dynastatic) = static_routes.static_routes(db)
  case path {
    "/" -> {
      console.log(
        premixed.text_ok_green("[ 200 ]\t")
        <> "(GET)\t"
        <> premixed.text_lightblue("/")
        <> " "
        <> premixed.text_cyan(
          "\t(this means client-side will now start loading a web page)",
        ),
      )
      dynastatic
      |> map.get("/index.html")
      |> result.unwrap(response.new())
      |> promise.resolve()
    }
    "/fetch/minimal-content-list" -> {
      console.log(
        premixed.text_ok_green("[ 200 ]\t")
        <> "(GET)\t"
        <> premixed.text_lightblue("/fetch/minimal-content-list"),
      )
      promise.resolve(
        response.new()
        |> response.set_body(
          content_data.get_minimal_content_list(db)
          |> content_data.minimal_json_encoder(),
        )
        |> response.set_headers(
          [#("Content-Type", "application/json; charset=utf-8")]
          |> array.from_list(),
        ),
      )
    }

    "/fetch/content/priority/" -> {
      use <-
        bool.lazy_guard({ { req |> request.method() } == "POST" }, _, fn() {
          console.error(
            premixed.text_error_red("[ 405 ] ")
            <> "("
            <> req |> request.method
            <> ")\t"
            <> premixed.text_lightblue("/fetch/content/priority/"),
          )
          response.new()
          |> response.set_body(
            "{ \"message\": \"Only POST requests are allowed here\" }",
          )
          |> response.set_status(405)
          |> response.set_headers(
            [#("Content-Type", "application/json; charset=utf-8")]
            |> array.from_list(),
          )
          |> promise.resolve()
        })
      // We get the content from the db and turn it into json, regardless of the kind. Client knows how to figure that out.
      let promise_of_an_url_path =
        req
        |> get_request_body()
      use url_path_as_a_bitarray <- promise.await(promise_of_an_url_path)
      let assert Ok(url_path) = url_path_as_a_bitarray |> bit_array.to_string()
      let url_path = case url_path |> string.ends_with("/") {
        True -> {
          url_path
          |> string.drop_end(1)
        }
        False -> url_path
      }

      case database.get_content_by_permalink(db, url_path) {
        Error(e) -> {
          console.error(
            premixed.text_error_red("[ 500 ] ")
            <> "(POST)\t"
            <> premixed.text_lightblue("/fetch/content/priority/")
            <> "{"
            <> premixed.text_orange(url_path)
            <> "}"
            <> premixed.text_lightblue("/")
            <> premixed.text_cyan(premixed.text_error_red("\t ERROR: " <> e)),
          )
          response.new()
          |> response.set_body("{ \"message\": \"Error fetching content.\" }")
          |> response.set_status(500)
          |> response.set_headers(
            [#("Content-Type", "application/json; charset=utf-8")]
            |> array.from_list(),
          )
        }
        Ok(None) -> {
          console.error(
            premixed.text_error_red("[ 404 ] ")
            <> "("
            <> req |> request.method
            <> ")\t"
            <> premixed.text_lightblue("/fetch/content/priority")
            <> "{"
            <> premixed.text_orange(case url_path {
              "" -> "/"
              _ -> url_path
            })
            <> "}",
          )
          dynastatic
          |> map.get("/404")
          |> result.unwrap(response.new())
        }
        Ok(Some(#(content_record, content_inner))) -> {
          let res =
            case content_record {
              ContentsPage(page_record) -> {
                json.object([
                  // Common to all content types
                  #("filename", json.string(page_record.filename)),
                  #("title", json.string(page_record.title)),
                  #("description", json.string(page_record.description)),
                  #("layout", json.string(page_record.layout)),
                  #("permalink", json.string(page_record.permalink)),
                  // Unique to unspecified content
                  #("kind", json.string("page")),
                  #("inner", json.string(content_inner)),
                  // Unique to page
                  #(
                    "page",
                    json.object([
                      #("menus", json.array(page_record.page.menus, json.int)),
                    ]),
                  ),
                  // Unique to post
                  #("post", json.null()),
                ])
              }
              ContentsPost(post_record) -> {
                json.object([
                  // Common to all content types
                  #("filename", json.string(post_record.filename)),
                  #("title", json.string(post_record.title)),
                  #("description", json.string(post_record.description)),
                  #("layout", json.string(post_record.layout)),
                  #("permalink", json.string(post_record.permalink)),
                  // Unique to unspecified content
                  #("kind", json.string("post")),
                  #("inner", json.string(content_inner)),
                  // Unique to page
                  #("page", json.null()),
                  // Unique to post
                  #(
                    "post",
                    json.object([
                      #(
                        "date-posted",
                        json.string(post_record.post.date_posted),
                      ),
                      #(
                        "date-updated",
                        json.string(post_record.post.date_updated),
                      ),
                      #("category", json.string(post_record.post.category)),
                      #("tags", json.array(post_record.post.tags, json.string)),
                    ]),
                  ),
                ])
              }
            }
            |> json.to_string()
          console.log(
            premixed.text_ok_green("[ 200 ]\t")
            <> "(POST)\t"
            <> premixed.text_lightblue("/fetch/content/priority")
            <> "{"
            <> premixed.text_orange(case url_path {
              "" -> "/"
              _ -> url_path
            })
            <> "}"
            <> premixed.text_cyan(
              "\t (this is probably the page the user is currently viewing, so client fetches it first!)",
            ),
          )
          response.new()
          |> response.set_body(res)
          |> response.set_status(200)
          |> response.set_headers(
            [#("Content-Type", "application/json; charset=utf-8")]
            |> array.from_list(),
          )
        }
      }
      |> promise.resolve()
    }

    "/fetch/content/" -> {
      use <-
        bool.lazy_guard({ { req |> request.method() } == "POST" }, _, fn() {
          console.error(
            premixed.text_error_red("[ 405 ] ")
            <> "("
            <> req |> request.method
            <> ")\t"
            <> premixed.text_lightblue("/fetch/content/"),
          )
          response.new()
          |> response.set_body(
            "{ \"message\": \"Only POST requests are allowed here\" }",
          )
          |> response.set_status(405)
          |> response.set_headers(
            [#("Content-Type", "application/json; charset=utf-8")]
            |> array.from_list(),
          )
          |> promise.resolve()
        })
      // We get the content from the db and turn it into json, regardless of the kind. Client knows how to figure that out.
      let promise_of_a_file_name =
        req
        |> get_request_body()
      use file_name_as_a_bitarray <- promise.await(promise_of_a_file_name)
      let assert Ok(file_name) =
        file_name_as_a_bitarray |> bit_array.to_string()
      case database.get_content_by_filename(db, file_name) {
        Error(e) -> {
          console.error(
            premixed.text_error_red("[ 500 ] ")
            <> "(POST)\t"
            <> premixed.text_lightblue("/fetch/content/")
            <> "{"
            <> premixed.text_orange(file_name)
            <> "}"
            <> premixed.text_lightblue("/")
            <> premixed.text_cyan(premixed.text_error_red("\t ERROR: " <> e)),
          )
          response.new()
          |> response.set_body("{ \"message\": \"Error fetching content.\" }")
          |> response.set_status(500)
          |> response.set_headers(
            [#("Content-Type", "application/json; charset=utf-8")]
            |> array.from_list(),
          )
        }
        Ok(#(content_record, content_inner)) -> {
          let res =
            case content_record {
              ContentsPage(page_record) -> {
                json.object([
                  // Common to all content types
                  #("filename", json.string(page_record.filename)),
                  #("title", json.string(page_record.title)),
                  #("description", json.string(page_record.description)),
                  #("layout", json.string(page_record.layout)),
                  #("permalink", json.string(page_record.permalink)),
                  // Unique to unspecified content
                  #("kind", json.string("page")),
                  #("inner", json.string(content_inner)),
                  // Unique to page
                  #(
                    "page",
                    json.object([
                      #("menus", json.array(page_record.page.menus, json.int)),
                    ]),
                  ),
                  // Unique to post
                  #("post", json.null()),
                ])
              }
              ContentsPost(post_record) -> {
                json.object([
                  // Common to all content types
                  #("filename", json.string(post_record.filename)),
                  #("title", json.string(post_record.title)),
                  #("description", json.string(post_record.description)),
                  #("layout", json.string(post_record.layout)),
                  #("permalink", json.string(post_record.permalink)),
                  // Unique to unspecified content
                  #("kind", json.string("post")),
                  #("inner", json.string(content_inner)),
                  // Unique to page
                  #("page", json.null()),
                  // Unique to post
                  #(
                    "post",
                    json.object([
                      #(
                        "date-posted",
                        json.string(post_record.post.date_posted),
                      ),
                      #(
                        "date-updated",
                        json.string(post_record.post.date_updated),
                      ),
                      #("category", json.string(post_record.post.category)),
                      #("tags", json.array(post_record.post.tags, json.string)),
                    ]),
                  ),
                ])
              }
            }
            |> json.to_string()
          console.log(
            premixed.text_ok_green("[ 200 ]\t")
            <> "(POST)\t"
            <> premixed.text_lightblue("/fetch/content/")
            <> "{"
            <> premixed.text_orange(file_name)
            <> "}"
            <> premixed.text_lightblue("/")
            <> premixed.text_cyan(
              "\t (these usually prefetch all the pages to build up a cache for quick responses!)",
            ),
          )
          response.new()
          |> response.set_body(res)
          |> response.set_status(200)
          |> response.set_headers(
            [#("Content-Type", "application/json; charset=utf-8")]
            |> array.from_list(),
          )
        }
      }
      |> promise.resolve()
    }
    // "/sitemap.xml" -> {
    //   console.log(
    //     premixed.text_ok_green("[ 200 ]\t")
    //     <> "(GET)\t"
    //     <> premixed.text_lightblue("/sitemap.xml"),
    //   )
    //   let requrl = req |> request.url()
    // }
    "/fetch/global-site-config" -> {
      promise.resolve(send_global_site_config(db))
    }
    f -> {
      console.error(
        premixed.text_error_red("[ 404 ] ")
        <> "("
        <> req |> request.method
        <> ")\t"
        <> premixed.text_lightblue(f),
      )
      dynastatic
      |> map.get("/404")
      |> result.unwrap(response.new())
      |> promise.resolve()
    }
  }
}

fn send_global_site_config(db: sqlite.Database) {
  case database.get__entire_global_config(db) {
    Ok(data) -> {
      response.new()
      |> response.set_body({
        json.object([
          #("site_name", json.string(data.global_site_name)),
          #("site_colour", json.string(data.global_colour)),
          #("site_description", json.string(data.global_site_description)),
          #("global_theme", json.string(data.global_theme)),
          #("global_theme_dark", json.string(data.global_theme_dark)),
        ])
        |> json.to_string()
      })
      |> response.set_headers(
        [#("Content-Type", "application/json; charset=utf-8")]
        |> array.from_list(),
      )
    }
    Error(_) -> {
      response.new()
      |> response.set_body(
        "{ \"message\": \"Error fetching global site config\" }",
      )
      |> response.set_status(500)
      |> response.set_headers(
        [#("Content-Type", "application/json; charset=utf-8")]
        |> array.from_list(),
      )
    }
  }
}

@external(javascript, "./request_ffi.ts", "get_request_body")
pub fn get_request_body(req: Request) -> Promise(BitArray)

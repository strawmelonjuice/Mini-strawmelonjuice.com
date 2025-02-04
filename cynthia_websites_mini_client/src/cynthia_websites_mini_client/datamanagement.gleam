import cynthia_websites_mini_client/datamanagement/database
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_shared/configtype
import gleam/dynamic/decode
import gleam/fetch
import gleam/http.{Post}
import gleam/http/request
import gleam/javascript/array
import gleam/javascript/promise
import gleam/result

@external(javascript, "./datamanagement_ffi.ts", "get_specific_item_from_global_config")
pub fn pull_from_global_config_table(
  what: String,
  db: database.SQLiteDB,
) -> Result(String, Nil)

pub fn populate_global_config_table(db: database.SQLiteDB) {
  let res =
    utils.phone_home()
    |> request.set_method(Post)
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
    database.run(db, "DELETE FROM globalConfig", [] |> array.from_list())
    database.run(
      db,
      "
INSERT INTO globalConfig (
        site_name,
        site_colour,
        site_description,
        theme,
        theme_dark,
        layout
      )
      VALUES (:name, :colour, :description, :theme, :darktheme, :layout);

  ",
      [
        #(":name", data.global_site_name),
        #(":colour", data.global_colour),
        #(":description", data.global_site_description),
        #(":theme", data.global_theme),
        #(":darktheme", data.global_theme_dark),
        #(":layout", data.global_layout),
      ]
        |> array.from_list(),
    )
    Ok(Nil)
  }
  |> promise.resolve
}

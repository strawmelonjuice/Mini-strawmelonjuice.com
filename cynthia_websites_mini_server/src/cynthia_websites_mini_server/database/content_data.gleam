import bungibindies/bun/sqlite
import bungibindies/bun/sqlite/param_array
import cynthia_websites_mini_shared/contenttypes
import gleam/dynamic/decode
import gleam/io
import gleam/javascript/array
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleamy_lights/premixed

pub fn get_minimal_content_list(
  db: sqlite.Database,
) -> List(contenttypes.Minimal) {
  let statement =
    sqlite.prepare(
      db,
      "
      SELECT meta_title, meta_description, meta_kind, meta_permalink, last_inserted_at, meta_original_file_path AS filename
      FROM contentStore
    ",
    )

  let rows = sqlite.all(statement, param_array.new())
  array.to_list(rows)
  |> list.try_map(decode.run(_, contenttypes.minimal_decoder()))
  |> result.map_error(fn(e) {
    premixed.text_error_red(
      "The was an error decoding the content metadata from the database:"
      <> {
        e
        |> string.inspect
      },
    )
    |> io.println()
    e
  })
  |> result.unwrap([])
}

pub fn minimal_json_encoder(what contents: List(contenttypes.Minimal)) -> String {
  list.map(contents, fn(content) {
    json.object([
      #("meta_title", json.string(content.meta_title)),
      #("meta_description", json.string(content.meta_description)),
      #(
        "meta_kind",
        json.int(content.meta_kind),
        // -- Deviates from the shared type, but would be preferred if not.
      // json.string({
      //   case content.meta_kind {
      //     0 -> "page"
      //     1 -> "post"
      //     f -> "unknown " <> int.to_string(f)
      //   }
      // }),
      ),
      #("meta_permalink", json.string(content.meta_permalink)),
      #("last_inserted_at", json.string(content.last_inserted_at)),
      #("filename", json.string(content.filename)),
    ])
  })
  |> json.preprocessed_array
  |> json.to_string
}

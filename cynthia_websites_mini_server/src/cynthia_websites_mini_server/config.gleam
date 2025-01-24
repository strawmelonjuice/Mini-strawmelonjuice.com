import bungibindies/bun/sqlite
import cynthia_websites_mini_server/database
import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_server/utils/prompts
import cynthia_websites_mini_shared/configtype
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleamy_lights/premixed
import plinth/javascript/console
import plinth/node/process
import simplifile

/// # Config.load()
/// Loads the configuration from the `cynthia-mini.toml` file and the content from the `content` directory.
/// Then saves the configuration to the database.
/// If an override environment variable or call param is provided, it will use that database file instead, and load from there. It will not need any files to exist in the filesystem (except for the SQLite file) in that case.
pub fn load() -> #(sqlite.Database, configtype.SharedCynthiaConfig) {
  let global_conf_filepath = process.cwd() <> "/cynthia-mini.toml"
  let global_conf_filepath_exists = files.file_exist(global_conf_filepath)
  case global_conf_filepath_exists {
    True -> Nil
    False -> {
      dialog_initcfg()
      Nil
    }
  }
  let global_config = case
    i_load(
      global_conf_filepath,
      configtype.default_shared_cynthia_config_global_only,
    )
  {
    Ok(config) -> config
    Error(why) -> {
      io.println_error("Error: Could not load cynthia-mini.toml: " <> why)
      io.println("Using default configuration.")
      configtype.default_shared_cynthia_config_global_only
    }
  }
  let content = case content_getter() {
    Ok(lis) -> lis
    Error(msg) -> {
      io.println_error(msg)
      panic as msg
    }
  }

  let conf =
    configtype.shared_merge_shared_cynthia_config(global_config, content)
  let db = database.create_database()
  store_db(db, conf)

  #(db, conf)
}

pub type ContentKindOnly {
  ContentKind(kind: String)
}

pub fn content_kind_only_decoder() -> decode.Decoder(ContentKindOnly) {
  use kind <- decode.field("kind", decode.string)
  decode.success(ContentKind(kind:))
}

@external(javascript, "./config_ffi.ts", "parse_configtoml")
fn i_load(
  from: String,
  default: configtype.SharedCynthiaConfigGlobalOnly,
) -> Result(configtype.SharedCynthiaConfigGlobalOnly, String)

fn content_getter() {
  {
    simplifile.get_files(process.cwd() <> "/content")
    |> result.unwrap([])
    |> list.filter(fn(file) { file |> string.ends_with(".meta.json") })
    |> list.map(fn(file) { file |> string.replace(".meta.json", "") })
    |> list.try_map(fn(file) -> Result(configtype.Contents, String) {
      use content <- result.try({
        simplifile.read(file <> ".meta.json")
        |> result.replace_error(
          "Error: Could not read file " <> file <> ".meta.json",
        )
      })
      use kind <- result.try({
        json.parse(content, content_kind_only_decoder())
        |> result.replace_error(
          "Error: Could not decode kind in " <> file <> ".meta.json",
        )
      })
      case kind.kind {
        "page" -> {
          use page <- result.try({
            json.parse(content, configtype.page_decoder(file))
            |> result.replace_error(
              "Error: Could not decode " <> file <> ".meta.json",
            )
          })
          Ok(configtype.ContentsPage(page))
        }
        "post" -> {
          use post <- result.try({
            json.parse(content, configtype.post_decoder(file))
            |> result.replace_error(
              "Error: Could not decode " <> file <> ".meta.json",
            )
          })
          Ok(configtype.ContentsPost(post))
        }
        _ -> Error("Error: Could not decode " <> file <> ".meta.json")
      }
    })
  }
}

pub fn store_db(
  db: sqlite.Database,
  conf: configtype.SharedCynthiaConfig,
) -> Nil {
  // TODO: Implement this
  // nil to continue
  Nil
}

fn dialog_initcfg() {
  console.clear()
  io.println("No Cynthia Mini configuration found...")
  case
    prompts.for_confirmation(
      "Initialise new config at this location?\n"
        <> "This will create a "
        <> premixed.text_bright_yellow("cynthia-mini.toml")
        <> " file and some sample content.\n\n",
      True,
    )
  {
    False -> {
      io.println_error("No Cynthia Mini configuration found... Exiting.")
      process.exit(1)
      panic as "We should not reach here"
    }
    True -> Nil
  }
  todo as "Implement the config writer."
}

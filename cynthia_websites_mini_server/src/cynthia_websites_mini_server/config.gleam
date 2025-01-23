import bungibindies/bun/sqlite
import cynthia_websites_mini_shared/configtype
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleamy_lights/premixed
import plinth/node/process
import question.{question}
import simplifile

pub fn load() -> configtype.SharedCynthiaConfig {
  let global_conf_filepath = process.cwd() <> "/cynthia-mini.toml"
  let global_conf_filepath_exists = simplifile.is_file(global_conf_filepath)
  case global_conf_filepath_exists {
    Ok(True) -> Nil
    _ -> {
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

  configtype.shared_merge_shared_cynthia_config(global_config, content)
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

pub fn store_db(db: sqlite.Database) -> Nil {
  // todo: Implement this
  // nil to continue
  Nil
}

fn dialog_initcfg() {
  io.println("No Cynthia Mini configuration found...")
  use <-
    dialog_initcfg_prompt_1(_, fn() {
      io.println_error("No Cynthia Mini configuration found... Exiting.")
      process.exit(1)
    })
  todo
}

fn dialog_initcfg_prompt_1(if_yes: fn() -> Nil, if_no: fn() -> Nil) -> Nil {
  use answer <- question(
    "Initialise new config at this location?\n"
    <> "This will create a "
    <> premixed.text_bright_yellow("cynthia-mini.toml")
    <> " file and some sample content.\n\n"
    <> "([Y]/n)",
  )
  io.println("Answer: " <> answer)
  case answer |> string.lowercase() {
    "" | "y" -> if_yes()
    "n" -> if_no()
    _ -> {
      io.println_error(
        "Did not expect that answer, please answer "
        <> premixed.text_green("y")
        <> "for yes, or "
        <> premixed.text_red("n")
        <> "for no.",
      )
      dialog_initcfg_prompt_1(if_yes, if_no)
    }
  }
}

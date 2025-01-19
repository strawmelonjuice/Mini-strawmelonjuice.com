import cynthia_websites_mini_shared
import gleam/io
import gleam/list
import plinth/node/process
import simplifile

pub fn load() -> cynthia_websites_mini_shared.SharedCynthiaConfig {
  let assert Ok(global_config) = i_load(process.cwd() <> "/cynthia-mini.toml")
  let assert Ok(filelist) = simplifile.get_files(process.cwd() <> "/content")

  let list =
    filelist
    // |> list.filter(fn(file) { file |> string.ends_with(".meta.json") })
    // |> list.map(fn(file) { file |> string.replace(".meta.json", "") })
    |> list.each(fn(file) { io.println(file) })
  todo
}

@external(javascript, "./config_ffi.ts", "parse_configtoml")
fn i_load(
  from: String,
) -> Result(cynthia_websites_mini_shared.SharedCynthiaConfigGlobalOnly, String)

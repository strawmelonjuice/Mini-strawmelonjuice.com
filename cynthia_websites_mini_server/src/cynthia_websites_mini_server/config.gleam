import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_server/utils/prompts
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/contenttypes
import gleam/dict
import gleam/fetch
import gleam/http/request
import gleam/javascript/promise
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleamy_lights/premixed
import plinth/javascript/console
import plinth/node/fs
import plinth/node/process
import simplifile
import tom

/// # Config.load()
/// Loads the configuration from the `cynthia-mini.toml` file and the content from the `content` directory.
/// Then saves the configuration to the database.
/// If an override environment variable or call param is provided, it will use that database file instead, and load from
/// there. It will not need any files to exist in the filesystem (except for the SQLite file) in that case.
pub fn load() -> configtype.CompleteData {
  let global_config = capture_config()
  let content = case content_getter() {
    Ok(lis) -> lis
    Error(msg) -> {
      console.error("Error: There was an error getting content:\n" <> msg)
      process.exit(1)
      panic as "We should not reach here"
    }
  }

  let complete_data = configtype.merge(global_config, content)
  complete_data
}

pub fn capture_config() {
  let global_conf_filepath =
    files.path_join([process.cwd(), "/cynthia-mini.toml"])
  let global_conf_filepath_exists = files.file_exist(global_conf_filepath)
  case global_conf_filepath_exists {
    True -> Nil
    False -> {
      dialog_initcfg()
      Nil
    }
  }
  let global_config = case parse_configtoml() {
    Ok(config) -> config
    Error(why) -> {
      premixed.text_error_red(
        "Error: Could not load cynthia-mini.toml: " <> why,
      )
      |> console.error
      process.exit(1)
      panic as "We should not reach here"
    }
  }
  global_config
}

fn parse_configtoml() {
  use str <- result.try(
    fs.read_file_sync(files.path_normalize(
      process.cwd() <> "/cynthia-mini.toml",
    ))
    |> result.map_error(fn(e) {
      premixed.text_error_red("Error: Could not read cynthia-mini.toml: " <> e)
      process.exit(1)
    })
    |> result.map_error(string.inspect),
  )
  use res <- result.try(tom.parse(str) |> result.map_error(string.inspect))

  use config <- result.try(
    cynthia_config_global_only_exploiter(res)
    |> result.map_error(string.inspect),
  )
  Ok(config)
}

type ConfigTomlDecodeError {
  TomlGetStringError(tom.GetError)
  TomlGetIntError(tom.GetError)
  FieldError(String)
}

fn cynthia_config_global_only_exploiter(o: dict.Dict(String, tom.Toml)) {
  use global_theme <- result.try({
    use field <- result.try(
      tom.get(o, ["global", "theme"])
      |> result.replace_error(FieldError("config->global.theme does not exist")),
    )
    tom.as_string(field)
    |> result.map_error(TomlGetStringError)
  })
  use global_theme_dark <- result.try({
    use field <- result.try(
      tom.get(o, ["global", "theme_dark"])
      |> result.replace_error(FieldError(
        "config->global.theme_dark does not exist",
      )),
    )
    tom.as_string(field)
    |> result.map_error(TomlGetStringError)
  })
  use global_colour <- result.try({
    use field <- result.try(
      tom.get(o, ["global", "colour"])
      |> result.replace_error(FieldError("config->global.colour does not exist")),
    )
    tom.as_string(field)
    |> result.map_error(TomlGetStringError)
  })
  use global_site_name <- result.try({
    use field <- result.try(
      tom.get(o, ["global", "site_name"])
      |> result.replace_error(FieldError(
        "config->global.site_name does not exist",
      )),
    )
    tom.as_string(field)
    |> result.map_error(TomlGetStringError)
  })
  use global_site_description <- result.try({
    use field <- result.try(
      tom.get(o, ["global", "site_description"])
      |> result.replace_error(FieldError(
        "config->global.site_description does not exist",
      )),
    )
    tom.as_string(field)
    |> result.map_error(TomlGetStringError)
  })
  let server_port =
    option.from_result({
      use field <- result.try(
        tom.get(o, ["server", "port"])
        |> result.replace_error(FieldError("config->server.port does not exist")),
      )
      tom.as_int(field)
      |> result.map_error(TomlGetIntError)
    })
  let server_host =
    option.from_result({
      use field <- result.try(
        tom.get(o, ["server", "host"])
        |> result.replace_error(FieldError("config->server.host does not exist")),
      )
      tom.as_string(field)
      |> result.map_error(TomlGetStringError)
    })
  let posts_comments = case
    tom.get(o, ["posts", "comments"]) |> result.map(tom.as_bool)
  {
    Ok(Ok(field)) -> {
      field
    }
    _ -> True
  }
  Ok(configtype.SharedCynthiaConfigGlobalOnly(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port:,
    server_host:,
    posts_comments:,
  ))
}

fn content_getter() {
  {
    simplifile.get_files(files.path_join([process.cwd() <> "/content"]))
    |> result.unwrap([])
    |> list.filter(fn(file) { file |> string.ends_with(".meta.json") })
    |> list.map(fn(file) {
      file
      |> string.replace(".meta.json", "")
      |> files.path_normalize()
    })
    |> list.try_map(fn(file: String) -> Result(contenttypes.Content, String) {
      // Now, we have all file names coming into this function.
      // Time to decode them all, and have
      use inner_plain <- result.try(
        simplifile.read(file)
        |> result.replace_error("FS error while reading ´" <> file <> "´."),
      )
      let decoder = contenttypes.content_decoder_and_merger(inner_plain, file)
      use meta_json <- result.try(
        simplifile.read(file <> ".meta.json")
        |> result.replace_error(
          "FS error while reading ´" <> file <> ".meta.json´.",
        ),
      )
      json.parse(meta_json, decoder)
      |> result.map_error(fn(e) {
        "Some error decoding metadata for ´"<> file |>premixed.text_magenta() <> "´: " <> string.inspect(e)
      })
    })
  }
}

fn dialog_initcfg() {
  console.log("No Cynthia Mini configuration found...")
  case
    prompts.for_confirmation(
      "CynthiaMini can create \n"
        <> premixed.text_orange(process.cwd() <> "/cynthia-mini.toml")
        <> "\n ...and some sample content.\n"
        <> premixed.text_magenta(
        "Do you want to initialise new config at this location?",
      ),
      True,
    )
  {
    False -> {
      console.error("No Cynthia Mini configuration found... Exiting.")
      process.exit(1)
      panic as "We should not reach here"
    }
    True -> Nil
  }
  let assert Ok(_) =
    simplifile.create_directory_all(process.cwd() <> "/content")
  let assert Ok(_) = simplifile.create_directory_all(process.cwd() <> "/assets")
  let _ =
    { process.cwd() <> "/cynthia-mini.toml" }
    |> fs.write_file_sync(
      "[global]
theme = \"autumn\"
theme_dark = \"night\"
colour = \"#FFFFFF\"
site_name = \"My Site\"
site_description = \"A big site on a mini Cynthia!\"
[server]
port = 8080
host = \"localhost\"
[posts]
comments = false
",
    )
    |> result.map_error(fn(e) {
      premixed.text_error_red("Error: Could not write cynthia-mini.toml: " <> e)
      process.exit(1)
    })
  {
    console.log("Downloading default site icon...")
    // Download https://raw.githubusercontent.com/strawmelonjuice/CynthiaWebsiteEngine-mini/refs/heads/main/asset/153916590.png to assets/site_icon.png
    // Ignore any errors, if it fails, it fails.
    let assert Ok(req) =
      request.to(
        "https://raw.githubusercontent.com/strawmelonjuice/CynthiaWebsiteEngine-mini/refs/heads/main/asset/153916590.png",
      )
    use resp <- promise.try_await(fetch.send(req))
    use resp <- promise.try_await(fetch.read_bytes_body(resp))
    case
      simplifile.write_bits(process.cwd() <> "/assets/site_icon.png", resp.body)
    {
      Ok(_) -> Nil
      Error(_) -> {
        console.error("Error: Could not write assets/site_icon.png")
        Nil
      }
    }
    promise.resolve(Ok(Nil))
  }
  {
    {
      add_item(
        [],
        "index.md",
        contenttypes.Content(
          filename: "",
          title: "Example index",
          description: "This is an example index page",
          layout: "theme",
          permalink: "/",
          data: contenttypes.PageData(in_menus: [1]),
          inner_plain: "# Hello, World


  1. Numbered lists
  2. Images: ![Gleam's Lucy mascot](https://gleam.run/images/lucy/lucy.svg)

  ## The world is big

  ### The world is a little smaller

  #### The world is tiny

  ##### The world is tinier

  ###### The world is the tiniest

  > Also quote blocks!
  >
  > -StrawmelonJuice

  ```bash
  echo \"Code blocks!\"
  // - StrawmelonJuice
  ```
  ",
        ),
      )
      |> add_item(
        to: "example-post.md",
        with: contenttypes.Content(
          filename: "",
          title: "An example post!",
          description: "This is an example post",
          layout: "theme",
          permalink: "/example-post",
          data: contenttypes.PostData(
            category: "example",
            date_published: "2021-01-01",
            date_updated: "2021-01-01",
            tags: ["example"],
            comments: [],
          ),
          inner_plain: "# Hello, World!\n\nHello! This is an example post, you'll find me at `content/example-post.md`.",
        ),
      )
      |> add_item(
        to: "posts",
        with: contenttypes.Content(
          filename: "posts",
          title: "Posts",
          description: "this page is not actually shown, due to the ! prefix in the permalink",
          layout: "default",
          permalink: "!/",
          data: contenttypes.PageData(in_menus: [1]),
          inner_plain: "",
        ),
      )
    }
    |> write_posts_and_pages_to_fs
  }
}

fn add_item(
  after others: List(#(String, String)),
  to path: String,
  with content: contenttypes.Content,
) -> List(#(String, String)) {
  let path = files.path_join([process.cwd(), "/content/", path])
  let meta_json =
    content
    |> contenttypes.encode_content_for_fs
    |> json.to_string()
  let meta_path = path <> ".meta.json"
  [#(meta_path, meta_json), #(path, content.inner_plain)]
  |> list.append(others)
}

// What? The function name is descriptive!
fn write_posts_and_pages_to_fs(items: List(#(String, String))) -> Nil {
  items
  |> list.each(fn(set) {
    let #(path, content) = set
    path
    |> fs.write_file_sync(content)
  })
}

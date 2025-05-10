import bungibindies/bun
import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_server/utils/prompts
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/contenttypes
import gleam/dict
import gleam/dynamic/decode
import gleam/fetch
import gleam/float
import gleam/http/request
import gleam/int
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
  let comment_repo = case
    tom.get(o, ["posts", "comment_repo"]) |> result.map(tom.as_string)
  {
    Ok(Ok(field)) -> {
      option.Some(field)
    }
    _ -> option.None
  }
  Ok(configtype.SharedCynthiaConfigGlobalOnly(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port:,
    server_host:,
    comment_repo:,
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
      use meta_json <- result.try(
        simplifile.read(file <> ".meta.json")
        |> result.replace_error(
          "FS error while reading ´" <> file <> ".meta.json´.",
        ),
      )
      // Sometimes stuff is saved somewhere else, like in a different file path or maybe somewhere on the web, of course Cynthia Mini can still find those files!
      // ...However, we first need to know there is an "external" file somewhere, we do that by checking the 'path' field.
      // The extension before .meta.json is still used to parse the content.
      let possibly_extern =
        json.parse(meta_json, {
          use path <- decode.optional_field("path", "", decode.string)
          decode.success(path)
        })
        |> result.unwrap("")
        |> string.to_option
      let permalink =
        json.parse(meta_json, {
          use path <- decode.optional_field("permalink", "", decode.string)
          decode.success(path)
        })
        |> result.unwrap("")
      use inner_plain <- result.try(
        // This case also check if the permalink starts with "!", in which case it is a content list.
        // Content lists will be generated on the client side, and their pre-given content 
        // will be discarded, so loading it in from anywhere would be a waste of resources.
        case string.starts_with(permalink, "!"), possibly_extern {
          True, _ -> Ok("")
          False, option.None -> {
            simplifile.read(file)
            |> result.replace_error("FS error while reading ´" <> file <> "´.")
          }
          False, option.Some(p) -> get_ext(p)
        },
      )

      let decoder = contenttypes.content_decoder_and_merger(inner_plain, file)
      json.parse(meta_json, decoder)
      |> result.map_error(fn(e) {
        "Some error decoding metadata for ´"
        <> file |> premixed.text_magenta()
        <> "´: "
        <> string.inspect(e)
      })
    })
  }
}

// especially to not have promise colouring 💔
@external(javascript, "./request_ffi.ts", "actual_call_to_curl")
fn actual_call_to_curl(url: String) -> Result(String, String)

/// Gets external content, beit by file path or by http(s) url.
fn get_ext(path: String) -> Result(String, String) {
  case string.starts_with(string.lowercase(path), "http") {
    True -> {
      let start = bun.nanoseconds()
      console.log(
        "Downloading external content ´" <> premixed.text_blue(path) <> "´...",
      )

      use res <- result.try(
        actual_call_to_curl(path)
        |> result.map_error(fn(b) { "Could not fetch external content: " <> b }),
      )
      let end = bun.nanoseconds()
      let duration_ms = { end -. start } /. 1_000_000.0

      console.log(
        "Downloaded external content ´"
        <> premixed.text_blue(path)
        <> "´ in "
        <> int.to_string(duration_ms |> float.truncate)
        <> "ms!",
      )
      Ok(res)
    }
    False -> {
      // Is a file path
      simplifile.read(path)
      |> result.replace_error(
        "FS error while reading external content file ´" <> path <> "´.",
      )
    }
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
  # Theme to use for light mode - default themes: autumn, default
  theme = \"autumn\"
  # Theme to use for dark mode - default themes: night, default-dark
  theme_dark = \"night\"
  # Primary color for accents and highlights
  colour = \"#FFFFFF\"
  # Your website's name, displayed in various places
  site_name = \"My Site\"
  # A brief description of your website
  site_description = \"A big site on a mini Cynthia!\"

  [server]
  # Port number for the web server
  port = 8080
  # Host address for the web server
  host = \"localhost\"

  [posts]
  # Enable comments on posts using utteranc.es
  # Format: \"username/repositoryname\"
  #
  # You will need to give the utterances bot access to your repo.
  # See https://github.com/apps/utterances to add the utterances bot to your repo
  comment_repo = \"\"
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
    console.log("Creating example content...")
    [
      item(
        to: "hangers.md",
        with: contenttypes.Content(
          filename: "hangers.md",
          title: "Hangers",
          description: "An example page about hangers",
          layout: "theme",
          permalink: "/hangers",
          data: contenttypes.PageData(in_menus: [2]),
          inner_plain: "I have no clue. What are hangers again?

This page will only show up if you have a layout with two or more menus available! :)",
        ),
      ),
      ext_item(
        to: "themes.md",
        from: "https://raw.githubusercontent.com/CynthiaWebsiteEngine/Mini/refs/heads/main/docs/themes.md",
        with: contenttypes.Content(
          filename: "themes.md",
          title: "Themes",
          description: "External page example, using the theme list.",
          layout: "theme",
          permalink: "/themes",
          data: contenttypes.PageData(in_menus: [1]),
          inner_plain: "",
        ),
      ),
      item(
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
      ),
      item(
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
          ),
          inner_plain: "# Hello, World!\n\nHello! This is an example post, you'll find me at `content/example-post.md`.",
        ),
      ),
      item(
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
      ),
    ]
    |> list.flatten
    |> write_posts_and_pages_to_fs
  }
}

fn item(
  to path: String,
  with content: contenttypes.Content,
) -> List(#(String, String)) {
  let path = files.path_join([process.cwd(), "/content/", path])
  let meta_json =
    content
    |> contenttypes.encode_content_for_fs
    |> json.to_string()
  let meta_path = path <> ".meta.json"
  case string.starts_with(content.permalink, "!") {
    True -> {
      // No content file for post lists.
      [#(meta_path, meta_json)]
    }
    False -> [#(meta_path, meta_json), #(path, content.inner_plain)]
  }
}

fn ext_item(
  to fpath: String,
  from path: String,
  with content: contenttypes.Content,
) -> List(#(String, String)) {
  let meta_json =
    json.object([
      #("path", json.string(path)),
      #("title", json.string(content.title)),
      #("description", json.string(content.description)),
      #("layout", json.string(content.layout)),
      #("permalink", json.string(content.permalink)),
      #("data", contenttypes.encode_content_data(content.data)),
    ])
    |> json.to_string()

  [
    #(
      files.path_join([process.cwd(), "/content/", fpath]) <> ".meta.json",
      meta_json,
    ),
  ]
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

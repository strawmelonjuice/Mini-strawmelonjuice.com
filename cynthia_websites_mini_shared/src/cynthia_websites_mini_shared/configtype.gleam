import cynthia_websites_mini_shared/contenttypes.{type Content}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}

pub type CompleteData {
  CompleteData(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_site_name: String,
    global_site_description: String,
    server_port: Option(Int),
    server_host: Option(String),
    posts_comments: Bool,
    content: List(Content),
  )
}

pub fn encode_complete_data(complete_data: CompleteData) -> json.Json {
  let CompleteData(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port:,
    server_host:,
    posts_comments:,
    content:,
  ) = complete_data
  json.object([
    #("global_theme", json.string(global_theme)),
    #("global_theme_dark", json.string(global_theme_dark)),
    #("global_colour", json.string(global_colour)),
    #("global_site_name", json.string(global_site_name)),
    #("global_site_description", json.string(global_site_description)),
    #("server_port", case server_port {
      None -> json.null()
      Some(value) -> json.int(value)
    }),
    #("server_host", case server_host {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
    #("posts_comments", json.bool(posts_comments)),
    #("content", json.array(content, contenttypes.encode_content)),
  ])
}

pub fn complete_data_decoder() -> decode.Decoder(CompleteData) {
  use global_theme <- decode.field("global_theme", decode.string)
  use global_theme_dark <- decode.field("global_theme_dark", decode.string)
  use global_colour <- decode.field("global_colour", decode.string)
  use global_site_name <- decode.field("global_site_name", decode.string)
  use global_site_description <- decode.field(
    "global_site_description",
    decode.string,
  )
  use server_port <- decode.field("server_port", decode.optional(decode.int))
  use server_host <- decode.field("server_host", decode.optional(decode.string))
  use posts_comments <- decode.field("posts_comments", decode.bool)
  use content <- decode.field(
    "content",
    decode.list(contenttypes.content_decoder()),
  )
  decode.success(CompleteData(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_site_name:,
    global_site_description:,
    server_port:,
    server_host:,
    posts_comments:,
    content:,
  ))
}

pub type SharedCynthiaConfigGlobalOnly {
  SharedCynthiaConfigGlobalOnly(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_site_name: String,
    global_site_description: String,
    server_port: Option(Int),
    server_host: Option(String),
    posts_comments: Bool,
  )
}

pub const default_shared_cynthia_config_global_only: SharedCynthiaConfigGlobalOnly = SharedCynthiaConfigGlobalOnly(
  global_theme: "autumn",
  global_theme_dark: "night",
  global_colour: "#FFFFFF",
  global_site_name: "My Site",
  global_site_description: "A big site on a mini Cynthia!",
  server_port: None,
  server_host: None,
  posts_comments: False,
)

pub fn shared_merge_shared_cynthia_config(
  orig: SharedCynthiaConfigGlobalOnly,
  content: List(Content),
) -> CompleteData {
  CompleteData(
    global_theme: orig.global_theme,
    global_theme_dark: orig.global_theme_dark,
    global_colour: orig.global_colour,
    global_site_name: orig.global_site_name,
    global_site_description: orig.global_site_description,
    server_port: orig.server_port,
    server_host: orig.server_host,
    posts_comments: orig.posts_comments,
    content:,
  )
}

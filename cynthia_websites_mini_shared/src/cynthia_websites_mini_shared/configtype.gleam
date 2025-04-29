import cynthia_websites_mini_shared/contenttypes.{type Content}
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}

pub type SharedCynthiaConfig {
  SharedCynthiaConfig(
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
) -> SharedCynthiaConfig {
  SharedCynthiaConfig(
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

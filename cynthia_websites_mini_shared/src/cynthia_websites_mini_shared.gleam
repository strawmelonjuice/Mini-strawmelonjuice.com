import gleam/dynamic/decode

pub type SharedCynthiaConfig {
  SharedCynthiaConfig(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_font: String,
    global_font_size: Int,
    global_site_name: String,
    global_site_description: String,
    content: List(Contents),
  )
}

pub type SharedCynthiaConfigGlobalOnly {
  SharedCynthiaConfigGlobalOnly(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_font: String,
    global_font_size: Int,
    global_site_name: String,
    global_site_description: String,
  )
}

pub fn shared_merge_shared_cynthia_config(
  orig: SharedCynthiaConfigGlobalOnly,
  content: List(Contents),
) -> SharedCynthiaConfig {
  SharedCynthiaConfig(
    global_theme: orig.global_theme,
    global_theme_dark: orig.global_theme_dark,
    global_colour: orig.global_colour,
    global_font: orig.global_font,
    global_font_size: orig.global_font_size,
    global_site_name: orig.global_site_name,
    global_site_description: orig.global_site_description,
    content:,
  )
}

pub fn shared_cynthia_config_decoder() -> decode.Decoder(SharedCynthiaConfig) {
  use global_theme <- decode.field("global_theme", decode.string)
  use global_theme_dark <- decode.field("global_theme_dark", decode.string)
  use global_colour <- decode.field("global_colour", decode.string)
  use global_font <- decode.field("global_font", decode.string)
  use global_font_size <- decode.field("global_font_size", decode.int)
  use global_site_name <- decode.field("global_site_name", decode.string)
  use global_site_description <- decode.field(
    "global_site_description",
    decode.string,
  )
  use content <- decode.field("content", decode.list(contents_decoder()))
  decode.success(SharedCynthiaConfig(
    global_theme:,
    global_theme_dark:,
    global_colour:,
    global_font:,
    global_font_size:,
    global_site_name:,
    global_site_description:,
    content:,
  ))
}

pub type Contents {
  Contents(
    title: String,
    description: String,
    content: String,
    content_type: ContentsType,
  )
}

fn contents_decoder() -> decode.Decoder(Contents) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use content <- decode.field("content", decode.string)
  use content_type <- decode.field(
    "content_type",
    todo as "Decoder for ContentsType",
  )
  decode.success(Contents(title:, description:, content:, content_type:))
}

pub type ContentsType {
  Markdown
  HTML
  Plain
}

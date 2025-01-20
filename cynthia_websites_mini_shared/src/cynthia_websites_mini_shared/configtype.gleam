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

pub const default_shared_cynthia_config_global_only: SharedCynthiaConfigGlobalOnly = SharedCynthiaConfigGlobalOnly(
  global_theme: "autumn",
  global_theme_dark: "coffee",
  global_colour: "#FFFFFF",
  global_font: "Fira Sans",
  global_font_size: 12,
  global_site_name: "My Site",
  global_site_description: "A big site on a mini Cynthia!",
)

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

// And contents
pub type Contents {
  ContentsPage(Page)
  ContentsPost(Post)
}

pub type Page {
  Page(
    filename: String,
    title: String,
    description: String,
    layout: String,
    permalink: String,
    page: PagePageData,
  )
}

pub fn page_decoder(filename) -> decode.Decoder(Page) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- decode.field("layout", decode.string)
  use permalink <- decode.field("permalink", decode.string)
  use page <- decode.field(
    "page",
    fn() -> decode.Decoder(PagePageData) {
      use menus <- decode.field("menus", decode.list(decode.int))
      decode.success(ContentsPagePageData(menus:))
    }(),
  )
  decode.success(Page(
    filename:,
    title:,
    description:,
    layout:,
    permalink:,
    page:,
  ))
}

pub type PagePageData {
  ContentsPagePageData(menus: List(Int))
}

pub type Post {
  Post(
    filename: String,
    title: String,
    description: String,
    layout: String,
    permalink: String,
  )
}

pub fn post_decoder(filename) -> decode.Decoder(Post) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- decode.field("layout", decode.string)
  use permalink <- decode.field("permalink", decode.string)
  decode.success(Post(filename:, title:, description:, layout:, permalink:))
}

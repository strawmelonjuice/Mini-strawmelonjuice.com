import gleam/dynamic/decode

pub type SharedCynthiaConfig {
  SharedCynthiaConfig(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_site_name: String,
    global_site_description: String,
    global_layout: String,
    content: List(Contents),
  )
}

pub type SharedCynthiaConfigGlobalOnly {
  SharedCynthiaConfigGlobalOnly(
    global_theme: String,
    global_theme_dark: String,
    global_colour: String,
    global_site_name: String,
    global_site_description: String,
    global_layout: String,
  )
}

pub const default_shared_cynthia_config_global_only: SharedCynthiaConfigGlobalOnly = SharedCynthiaConfigGlobalOnly(
  global_theme: "autumn",
  global_theme_dark: "coffee",
  global_colour: "#FFFFFF",
  global_site_name: "My Site",
  global_site_description: "A big site on a mini Cynthia!",
  global_layout: "cyndy",
)

pub fn shared_merge_shared_cynthia_config(
  orig: SharedCynthiaConfigGlobalOnly,
  content: List(Contents),
) -> SharedCynthiaConfig {
  SharedCynthiaConfig(
    global_theme: orig.global_theme,
    global_theme_dark: orig.global_theme_dark,
    global_colour: orig.global_colour,
    global_site_name: orig.global_site_name,
    global_site_description: orig.global_site_description,
    global_layout: orig.global_layout,
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
    // Common to all content
    filename: String,
    title: String,
    description: String,
    layout: String,
    permalink: String,
    // Unique to page
    page: PagePageData,
  )
}

/// Data unique to page type content
pub type PagePageData {
  ContentsPagePageData(menus: List(Int))
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

pub type Post {
  Post(
    // Common to all content
    filename: String,
    title: String,
    description: String,
    layout: String,
    permalink: String,
    // Unique to post
    post: PostMetaData,
  )
}

/// Data unique to post type content
pub type PostMetaData {
  PostMetaData(
    /// Date in the  ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
    date_posted: String,
    /// Date in the  ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
    date_updated: String,
    /// Category this post belongs to
    category: String,
    /// Tags that belong to this post
    tags: List(String),
  )
}

pub fn post_decoder(filename) -> decode.Decoder(Post) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- decode.field("layout", decode.string)
  use permalink <- decode.field("permalink", decode.string)
  use post <- decode.field(
    "post",
    fn() -> decode.Decoder(PostMetaData) {
      use date_posted <- decode.field("date-posted", decode.string)
      use date_updated <- decode.field("date-updated", decode.string)
      use category <- decode.field("category", decode.string)
      use tags <- decode.field("tags", decode.list(decode.string))
      decode.success(PostMetaData(date_posted:, date_updated:, category:, tags:))
    }(),
  )
  decode.success(Post(
    filename:,
    title:,
    description:,
    layout:,
    permalink:,
    post:,
  ))
}

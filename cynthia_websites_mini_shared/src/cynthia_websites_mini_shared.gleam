import gleam_community/colour.{type Colour}

pub type SharedCynthiaConfig {
  SharedCynthiaConfig(
    global_theme: String,
    global_colour: Colour,
    // global_font: String,
    // global_font_size: Int,
    global_site_name: String,
    global_site_description: String,
    content: List(Contents),
  )
}

pub type Contents {
  Contents(
    title: String,
    description: String,
    content: String,
    content_type: ContentsType,
  )
}

pub type ContentsType {
  Markdown
  HTML
  Plain
}

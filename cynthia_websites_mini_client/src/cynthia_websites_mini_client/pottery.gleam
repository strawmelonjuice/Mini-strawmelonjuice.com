import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/pottery/molds
import cynthia_websites_mini_client/pottery/paints
import cynthia_websites_mini_shared/configtype
import gleam/bool
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute.{attribute}
import lustre/element
import lustre/element/html
import lustre/internals/vdom
import plinth/javascript/console

pub fn render_content(
  store: clientstore.ClientStore,
  data: configtype.Contents,
  inner: String,
  is priority: Bool,
) -> vdom.Element(a) {
  let is_a_postlist = case data {
    configtype.ContentsPage(r) -> string.starts_with(r.permalink, "!")
    configtype.ContentsPost(_) -> False
  }
  use <- bool.lazy_guard(is_a_postlist, fn() {
    console.log("Post list is kept unrendered for the cache")
    html.data([], [])
  })
  let assert Ok(def) = paints.get_sytheme(store)
  let #(into, content, variables) = case data {
    configtype.ContentsPage(page_data) -> {
      let mold = case page_data.layout {
        "default" | "theme" | "" ->
          molds.into(def.layout, "page", store, priority)
        layout -> molds.into(layout, "page", store, priority)
      }
      let description =
        page_data.description
        |> parse_html("descr.md")
        |> element.to_string
      let variables =
        dict.new()
        |> dict.insert("title", page_data.title)
        |> dict.insert("description_html", description)
        |> dict.insert("description", page_data.description)
      #(mold, parse_html(inner, page_data.filename), variables)
    }
    configtype.ContentsPost(post_data) -> {
      let mold = case post_data.layout {
        "default" | "theme" | "" ->
          molds.into(def.layout, "post", store, priority)
        layout -> molds.into(layout, "post", store, priority)
      }
      let description =
        post_data.description
        |> parse_html("descr.md")
        |> element.to_string
      let variables =
        dict.new()
        |> dict.insert("title", post_data.title)
        |> dict.insert("description_html", description)
        |> dict.insert("description", post_data.description)
        |> dict.insert("date_published", post_data.post.date_posted)
        |> dict.insert("date_modified", post_data.post.date_updated)
        |> dict.insert("category", post_data.post.category)
        |> dict.insert("tags", post_data.post.tags |> string.join(", "))
      #(mold, parse_html(inner, post_data.filename), variables)
    }
  }
  // Other stuff should be added to vars here, like site metadata, ~menu links~, etc. EDIT: Menu links go in their own thing.
  let site_name =
    clientstore.pull_from_global_config_table(store, "site_name")
    |> result.unwrap("My Site Name")
  into(content, variables |> dict.insert("global_site_name", site_name))
}

pub fn parse_html(inner: String, filename: String) -> vdom.Element(a) {
  case filename |> string.split(".") |> list.last {
    // Markdown is rendered with a custom renderer. After that, it can be pasted into the template.
    Ok("md") | Ok("markdown") | Ok("mdown") ->
      html.div(
        [attribute("dangerous-unescaped-html", custom_md_render(inner))],
        [],
      )
    // HTML/SVG is directly pastable into the template.
    Ok("html") | Ok("htm") | Ok("svg") ->
      html.div([attribute("dangerous-unescaped-html", inner)], [])
    // Text is wrapped in a <pre> tag. Then it can be pasted into the template.
    Ok("txt") -> html.pre([], [html.text(inner)])
    // Anything else is wrapped in a <pre> tag with a red color. Then it can be pasted into the template. This shows that the file type is not supported.
    _ ->
      html.div([], [
        html.text("Unsupported file type: "),
        html.text(filename),
        html.pre([attribute.class("text-red-500")], [
          html.text(string.inspect(inner)),
        ]),
      ])
  }
}

@external(javascript, "./pottery/markdown_renders_ffi.ts", "custom_render")
pub fn custom_md_render(markdown: String) -> String

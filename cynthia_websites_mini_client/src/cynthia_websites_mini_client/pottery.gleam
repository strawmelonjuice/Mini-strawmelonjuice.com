import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/pottery/molds
import cynthia_websites_mini_client/pottery/paints
import cynthia_websites_mini_shared/configtype
import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import lustre/attribute.{attribute}
import lustre/element/html
import lustre/internals/vdom

pub fn render_content(
  store: clientstore.ClientStore,
  data: configtype.Contents,
  inner: String,
) -> vdom.Element(a) {
  let assert Ok(def) = paints.get_sytheme(store)
  let #(into, content, variables) = case data {
    configtype.ContentsPage(page_data) -> {
      let mold = case page_data.layout {
        "default" | "theme" | "" -> molds.into(def.layout, "page", store)
        layout -> molds.into(layout, "page", store)
      }
      let variables = dict.new()
      #(mold, parse_html(inner, page_data.filename), variables)
    }
    configtype.ContentsPost(post_data) -> {
      let mold = case post_data.layout {
        "default" | "theme" | "" -> molds.into(def.layout, "post", store)
        layout -> molds.into(layout, "post", store)
      }
      let variables: Dict(String, String) =
        dict.new()
        |> dict.insert("date_published", post_data.post.date_posted)
        |> dict.insert("date_modified", post_data.post.date_updated)
        |> dict.insert("category", post_data.post.category)
        |> dict.insert("tags", post_data.post.tags |> string.join(", "))
      #(mold, parse_html(inner, post_data.filename), variables)
    }
  }
  // Other stuff should be added to vars here, like site metadata, ~menu links~, etc. EDIT: Menu links go in their own thing.
  into(content, variables)
}

fn parse_html(inner: String, filename: String) -> vdom.Element(a) {
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
      html.pre([attribute.class("text-red-500")], [
        html.text(string.inspect(inner)),
      ])
  }
}

@external(javascript, "./pottery/markdown_renders_ffi.ts", "custom_render")
pub fn custom_md_render(markdown: String) -> String

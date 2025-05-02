import cynthia_websites_mini_client/model_type.{type Model}
import cynthia_websites_mini_client/pottery/molds
import cynthia_websites_mini_client/pottery/paints
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/contenttypes
import gleam/bool
import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html

pub fn render_content(
  model: Model,
  content: contenttypes.Content,
  inner: String,
) -> Element(a) {
  let is_a_postlist = case content.data {
    contenttypes.PageData(..) -> string.starts_with(content.permalink, "!")
    contenttypes.PostData(..) -> False
  }
  use <- bool.lazy_guard(is_a_postlist, fn() { html.data([], []) })
  let assert Ok(def) = paints.get_sytheme(model)
  let #(into, content, variables) = case content.data {
    contenttypes.PageData(_) -> {
      let mold = case content.layout {
        "default" | "theme" | "" -> molds.into(def.layout, "page", model)
        layout -> molds.into(layout, "page", model)
      }
      let description =
        content.description
        |> parse_html("descr.md")
        |> element.to_string
      let variables =
        dict.new()
        |> dict.insert("title", content.title |> dynamic.from)
        |> dict.insert("description_html", description |> dynamic.from)
        |> dict.insert("description", content.description |> dynamic.from)
      #(mold, parse_html(inner, content.filename), variables)
    }
    contenttypes.PostData(
      category:,
      date_published:,
      date_updated:,
      comments:,
      tags:,
    ) -> {
      let mold = case content.layout {
        "default" | "theme" | "" -> molds.into(def.layout, "post", model)
        layout -> molds.into(layout, "post", model)
      }
      let description =
        content.description
        |> parse_html("descr.md")
        |> element.to_string
      let variables =
        dict.new()
        |> dict.insert("title", dynamic.from(content.title))
        |> dict.insert("description_html", description |> dynamic.from)
        |> dict.insert("description", content.description |> dynamic.from)
        |> dict.insert("date_published", date_published |> dynamic.from)
        |> dict.insert("date_modified", date_updated |> dynamic.from)
        |> dict.insert("comments", comments |> dynamic.from)
        |> dict.insert("category", category |> dynamic.from)
        |> dict.insert("tags", tags |> string.join(", ") |> dynamic.from)
      #(mold, parse_html(inner, content.filename), variables)
    }
  }
  // Other stuff should be added to vars here, like site metadata, ~menu links~, etc. EDIT: Menu links go in their own thing.
  let site_name =
    model.complete_data
    |> option.map(fn(a) { a.global_site_name })
    |> option.to_result(Nil)
    |> result.unwrap("My Site Name")
  into(
    content,
    variables |> dict.insert("global_site_name", dynamic.from(site_name)),
  )
}

pub fn parse_html(inner: String, filename: String) -> Element(a) {
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

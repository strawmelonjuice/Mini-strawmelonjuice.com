import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/messages
import cynthia_websites_mini_client/model_type.{type Model}
import cynthia_websites_mini_client/pottery/molds
import cynthia_websites_mini_client/pottery/paints
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/contenttypes
import gleam/dict
import gleam/dynamic
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import qs

pub fn render_content(
  model: Model,
  content: contenttypes.Content,
) -> Element(messages.Msg) {
  let assert Ok(def) = paints.get_sytheme(model)

  let #(into, output, variables) = case content.data {
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
      #(mold, parse_html(content.inner_plain, content.filename), variables)
    }
    contenttypes.PostData(category:, date_published:, date_updated:, tags:) -> {
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
        |> dict.insert("category", category |> dynamic.from)
        |> dict.insert("tags", tags |> string.join(", ") |> dynamic.from)
      #(mold, parse_html(content.inner_plain, content.filename), variables)
    }
  }
  // Other stuff should be added to vars here, like site metadata, ~menu links~, etc. EDIT: Menu links go in their own thing.
  let site_name =
    model.complete_data
    |> option.map(fn(a) { a.global_site_name })
    |> option.to_result(Nil)
    |> result.unwrap("My Site Name")
  let considered_output =
    {
      let default = [output]
      case content.data, model {
        contenttypes.PostData(..),
          model_type.Model(
            complete_data: option.Some(configtype.CompleteData(
              comment_repo: option.Some(repo),
              ..,
            )),
            ..,
          )
          if repo != ""
        -> {
          let comment_color_scheme = case dom.get_color_scheme() {
            "dark" -> "github-dark"
            _ -> "github-light"
          }
          let query =
            [
              #("async", []),
              #("crossorigin", ["anonymous"]),
              #("issue-term", [content.permalink]),
              #("repo", [repo]),
              #("src", ["https://utteranc.es/client.js"]),
              #("theme", [comment_color_scheme]),
              #("url", [utils.phone_home_url() <> "/#" <> model.path]),
              #("origin", [utils.phone_home_url()]),
              #("pathname", [model.path]),
              #("title", [content.title]),
              #("description", [content.description]),
              #("og:title", []),
              #("session", []),
            ]
            |> dict.from_list
            |> qs.default_serialize()

          let src = "https://utteranc.es/utterances.html" <> query
          list.append(default, [
            html.iframe([
              attribute("loading", "lazy"),
              attribute.src(src),
              // attribute("scrolling", "yes"),
              attribute("title", "Comments"),
              attribute.class(
                "utterances-frame w-full min-h-[30vh] h-full outline-none focus:outline-none o",
              ),
            ]),
          ])
        }
        _, _ -> default
      }
    }
    |> html.div([attribute.class("contents")], _)
  html.div(
    [
      attribute("data-theme", def.daisy_ui_theme_name),
      attribute.class("contents"),
    ],
    {
      [
        into(
          considered_output,
          variables |> dict.insert("global_site_name", dynamic.from(site_name)),
        ),
      ]
    },
  )
}

pub fn parse_html(inner: String, filename: String) -> Element(messages.Msg) {
  case filename |> string.split(".") |> list.last {
    // Markdown is rendered with a custom renderer. After that, it can be pasted into the template.
    Ok("md") | Ok("markdown") | Ok("mdown") ->
      element.unsafe_raw_html("div", "div", [], custom_md_render(inner))
    // HTML/SVG is directly pastable into the template.
    Ok("html") | Ok("htm") | Ok("svg") ->
      element.unsafe_raw_html("div", "div", [], inner)
    // Text is wrapped in a <pre> tag. Then it can be pasted into the template.
    //
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

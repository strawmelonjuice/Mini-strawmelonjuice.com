import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/pottery/molds
import cynthia_websites_mini_client/pottery/paints
import cynthia_websites_mini_shared/configtype
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/string
import kirala/markdown/parser
import lustre/internals/vdom

pub fn render_content(
  store: clientstore.ClientStore,
  data: configtype.Contents,
  inner: String,
) -> vdom.Element(a) {
  let #(f, vars): #(
    fn(Dict(String, String)) -> vdom.Element(a),
    Dict(String, String),
  ) = case data {
    configtype.ContentsPage(page_data) -> {
      let assert Ok(def) = paints.get_sytheme(store)
      let mold = case page_data.layout {
        "default" -> molds.into(def.layout, "page")
        "theme" -> molds.into(def.layout, "page")
        "" -> molds.into(def.layout, "page")
        layout -> molds.into(layout, "page")
      }
      let var =
        dict.new()
        |> dict.insert("content", parse_html(inner, page_data.filename))
      #(mold, var)
    }
    configtype.ContentsPost(_) -> todo
  }
  f(vars)
}

fn parse_html(inner: String, filename: String) -> String {
  let ext = filename |> string.split(".") |> list.last
  case ext {
    Ok("md") -> {
      let parsed =
        parser.parse(1, inner)
        |> io.debug
      todo
    }
    Ok("html") -> inner
    Ok(text) -> "<pre>" <> text <> "</pre>"
    Error(_) -> "<pre>" <> string.inspect(inner) <> "</pre>"
  }
}

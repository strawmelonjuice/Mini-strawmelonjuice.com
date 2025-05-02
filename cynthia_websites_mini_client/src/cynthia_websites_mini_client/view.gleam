import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/messages.{
  type Msg, UserComment, UserNavigateTo,
}
import cynthia_websites_mini_client/model_type.{type Model}
import cynthia_websites_mini_shared/configtype
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn main(model: Model) -> Element(Msg) {
  case model.complete_data {
    None -> initial_view()
    Some(p) ->
      todo as "What to do in view when there's like... data and stuff...?..."
  }
}

pub fn initial_view() -> Element(Msg) {
  let assert Ok(_) = dom.push_title("Cynthia Mini: Loading...")
  html.div(
    [
      attribute.class(
        "absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit",
      ),
    ],
    [
      html.div([attribute.class("card bg-primary text-primary-content w-96")], [
        html.div([attribute.class("card-body")], [
          html.h2([attribute.class("card-title")], [html.text("Cynthia Mini")]),
          html.p([], [html.text("Loading the page you want...")]),
          html.div([attribute.class("card-actions justify-end")], [
            html.span([attribute.class("loading loading-bars loading-lg")], []),
          ]),
        ]),
      ]),
    ],
  )
}

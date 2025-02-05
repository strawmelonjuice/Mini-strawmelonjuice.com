import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/pottery/oven
import gleam/string
import lustre/attribute
import lustre/element/html

pub fn loading_screen() -> Nil {
  case
    dom.push(
      "Cynthia Mini: Loading...",
      html.div(
        [
          attribute.class(
            "absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit",
          ),
        ],
        [
          html.div(
            [attribute.class("card bg-primary text-primary-content w-96")],
            [
              html.div([attribute.class("card-body")], [
                html.h2([attribute.class("card-title")], [
                  html.text("Cynthia Mini"),
                ]),
                html.p([], [html.text("Loading the page you want...")]),
                html.div([attribute.class("card-actions justify-end")], [
                  html.span(
                    [attribute.class("loading loading-bars loading-lg")],
                    [],
                  ),
                ]),
              ]),
            ],
          ),
        ],
      ),
    )
  {
    Ok(_) -> Nil
    Error(e) -> {
      oven.error("Error loading the loading screen:\n" <> string.inspect(e))
    }
  }
}

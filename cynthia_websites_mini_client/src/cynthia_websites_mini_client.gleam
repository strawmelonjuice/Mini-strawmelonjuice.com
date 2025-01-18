import cynthia_websites_mini_client/dom
import lustre/attribute
import lustre/element/html

pub fn main() {
  loading_screen()
  todo as "Nothing after the loading screen yet!"
}

fn loading_screen() -> Nil {
  case
    dom.push(
      "Loading...",
      html.div(
        [
          attribute.class(
            "absolute right-[40VW] left-[40VW] bottom-[40VH] top-[40VH] w-fit h-fit",
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
                    [attribute.class("loading loading-infinity loading-lg")],
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
      panic as e
    }
  }
}

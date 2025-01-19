import cynthia_websites_mini_client/dom
import lustre/attribute
import lustre/element/html

pub fn error(msg: String) -> Nil {
  case
    dom.push(
      "Cynthia Mini: Error!",
      html.div(
        [
          attribute.class(
            "absolute right-[40VW] left-[40VW] bottom-[40VH] top-[40VH] w-fit h-fit",
          ),
        ],
        [
          html.div(
            [attribute.class("card bg-neutral text-neutral-content w-96")],
            [
              html.div([attribute.class("card-body items-center text-center")], [
                html.h2([attribute.class("card-title")], [html.text("Error")]),
                html.p([], [html.text(msg)]),
                html.div([attribute.class("card-actions justify-end")], [
                  html.a(
                    [
                      attribute.href("javascript:window.location.reload(1)"),
                      attribute.class("btn btn-primary"),
                    ],
                    [html.text("Refresh")],
                  ),
                  html.a(
                    [
                      attribute.class("btn btn-ghost"),
                      attribute.href("javascript:window.history.back(1)"),
                    ],
                    [html.text("Go back")],
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

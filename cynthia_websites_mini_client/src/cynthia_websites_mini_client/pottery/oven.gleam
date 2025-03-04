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
            "absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit",
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
                      attribute.class("btn btn-neutral-300"),
                    ],
                    [html.text("Refresh")],
                  ),
                  html.a(
                    [
                      attribute.class("btn btn-ghost"),
                      attribute.href(
                        "javascript:window.history.back(1);javascript:window.location.reload()",
                      ),
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

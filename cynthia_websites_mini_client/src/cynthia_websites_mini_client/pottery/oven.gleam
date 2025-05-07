import cynthia_websites_mini_client/dom
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn error(msg: String) -> Element(a) {
  let assert Ok(_) = dom.push_title("Cynthia Mini: Error!")
  html.div(
    [
      attribute.class(
        "absolute mr-auto ml-auto right-0 left-0 bottom-[40VH] top-[40VH] w-fit h-fit",
      ),
    ],
    [
      html.div([attribute.class("card bg-neutral text-neutral-content w-96")], [
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
                  // You might think "oh no, this isn't activating any lustre messages". Think again.
                  // We WANT to do a fresh page load here. It's an error, so we
                  // can safely assume lustre doesn't know how to get out.
                  "javascript:window.history.back(1);javascript:window.location.reload()",
                ),
              ],
              [html.text("Go back")],
            ),
          ]),
        ]),
      ]),
    ],
  )
}

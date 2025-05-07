import cynthia_websites_mini_client/model_type.{type Model}
import cynthia_websites_mini_client/pottery
import cynthia_websites_mini_shared/contenttypes.{PostData}
import gleam/list
import gleam/option
import gleam/result
import lustre/attribute
import lustre/element
import lustre/element/html

fn fetch_post_list(model: Model) {
  model.complete_data
  |> option.to_result(Nil)
  |> result.map(fn(complete) {
    complete.content
    |> list.filter(fn(item) {
      case item.data {
        PostData(..) -> True
        _ -> False
      }
    })
  })
  |> result.unwrap([])
}

pub fn postlist_all(model: Model) {
  fetch_post_list(model)
  |> postlist_to_html
}

pub fn postlist_by_tag(model: Model, card: String) {
  fetch_post_list(model)
  |> list.filter(fn(post) {
    let assert PostData(
      date_published: _date_published,
      date_updated: _date_updated,
      category: _category,
      tags:,
    ): contenttypes.ContentData = post.data
    tags |> list.contains(card)
  })
  |> postlist_to_html
}

pub fn postlist_by_category(model: Model, cat: String) {
  fetch_post_list(model)
  |> list.filter(fn(post) {
    let assert PostData(
      date_published: _date_published,
      date_updated: _date_updated,
      category:,
      tags: _tags,
    ) = post.data
    category == cat
  })
  |> postlist_to_html
}

fn postlist_to_html(posts: List(contenttypes.Content)) -> element.Element(a) {
  let postlist =
    posts
    |> list.map(fn(post) {
      let assert PostData(
        date_published:,
        date_updated:,
        category: _category,
        tags: _tags,
      ) = post.data
      html.li([attribute.class("list-row p-10")], [
        html.a(
          [
            attribute.href("/#" <> post.permalink),
            attribute.class("post__link"),
          ],
          [
            html.div(
              [attribute.class("text-xs uppercase font-semibold opacity-60")],
              case date_published == date_updated {
                True -> [html.text(date_published)]
                False -> [
                  html.text(date_published),
                  html.text(" (updated "),
                  html.text(date_updated),
                  html.text(")"),
                ]
              },
            ),
            html.div([attribute.class("text-center text-xl")], [
              html.text(post.title),
            ]),
            html.blockquote(
              [
                attribute.class(
                  "list-col-wrap text-sm border-l-2 border-accent border-dotted pl-4 bg-secondary bg-opacity-10",
                ),
              ],
              [pottery.parse_html(post.description, "descr.md")],
            ),
          ],
        ),
      ])
    })
  html.ul(
    [attribute.class("postlist list bg-base-200 rounded-box shadow-md")],
    postlist,
  )
}
/// Comments are stored as a list of `Comment`s.

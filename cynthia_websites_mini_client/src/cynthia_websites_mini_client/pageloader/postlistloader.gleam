import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/pottery
import gleam/javascript/array
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html

pub fn postlist_all(store: datamanagement.ClientStore) {
  datamanagement.fetch_post_list(store)
  |> array.to_list
  |> postlist_to_html
}

pub fn postlist_by_tag(store: datamanagement.ClientStore, tag: String) {
  datamanagement.fetch_post_list(store)
  |> array.to_list
  |> list.filter(fn(post) {
    list.contains(post.meta_tags |> array.to_list(), tag)
  })
  |> postlist_to_html
}

pub fn postlist_by_category(store: datamanagement.ClientStore, category: String) {
  datamanagement.fetch_post_list(store)
  |> array.to_list
  |> list.filter(fn(post) { post.meta_category == category })
  |> postlist_to_html
}

fn postlist_to_html(posts: List(datamanagement.PostListItem)) {
  let postlist =
    posts
    |> list.map(fn(post) {
      html.li([attribute.class("list-row p-10")], [
        html.a(
          [
            attribute.href("/#" <> post.meta_permalink),
            attribute.class("post__link"),
          ],
          [
            html.div(
              [attribute.class("text-xs uppercase font-semibold opacity-60")],
              case post.meta_date_posted == post.meta_date_updated {
                True -> [html.text(post.meta_date_posted)]
                False -> [
                  html.text(post.meta_date_posted),
                  html.text(" (updated "),
                  html.text(post.meta_date_updated),
                  html.text(")"),
                ]
              },
            ),
            html.div([attribute.class("text-center text-xl")], [
              html.text(post.meta_title),
            ]),
            html.blockquote(
              [
                attribute.class(
                  "list-col-wrap text-sm border-l-2 border-accent border-dotted pl-4 bg-secondary bg-opacity-10",
                ),
              ],
              [pottery.parse_html(post.meta_description, "descr.md")],
            ),
          ],
        ),
      ])
    })
  html.ul(
    [attribute.class("postlist list bg-base-200 rounded-box shadow-md")],
    postlist,
  )
  |> element.to_string()
}

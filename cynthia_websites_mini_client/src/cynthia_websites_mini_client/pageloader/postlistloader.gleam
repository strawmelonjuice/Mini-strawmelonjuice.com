import cynthia_websites_mini_client/datamanagement
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
      html.li([attribute.class(" list-row btn-lg")], [
        html.a(
          [
            attribute.href("/#" <> post.meta_permalink),
            attribute.class("post__link"),
          ],
          [
            html.div([attribute.class("text-center")], [
              html.text(post.meta_title),
            ]),
            html.div(
              [attribute.class("text-xs uppercase font-semibold opacity-60")],
              // TODO: Add date support
              [html.text("")],
            ),
            html.p([attribute.class("list-col-wrap text-xs")], [
              html.text(post.meta_description),
            ]),
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

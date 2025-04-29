import gleam/dynamic/decode
import gleam/json

// Content main type ----------------------------------------------------------------------------
/// Type storing all info it parses from files and json metadatas
pub type Content {
  Content(
    filename: String,
    title: String,
    description: String,
    layout: String,
    permalink: String,
    inner_plain: String,
    data: ContentData,
  )
}

pub fn content_decoder() -> decode.Decoder(Content) {
  use filename <- decode.field("filename", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use layout <- decode.field("layout", decode.string)
  use permalink <- decode.field("permalink", decode.string)
  use inner_plain <- decode.field("inner_plain", decode.string)
  use data <- decode.field("data", content_data_decoder())
  decode.success(Content(
    filename:,
    title:,
    description:,
    layout:,
    permalink:,
    inner_plain:,
    data:,
  ))
}

pub fn encode_content(content: Content) -> json.Json {
  let Content(
    filename:,
    title:,
    description:,
    layout:,
    permalink:,
    inner_plain:,
    data:,
  ) = content
  json.object([
    #("filename", json.string(filename)),
    #("title", json.string(title)),
    #("description", json.string(description)),
    #("layout", json.string(layout)),
    #("permalink", json.string(permalink)),
    #("inner_plain", json.string(inner_plain)),
    #("data", encode_content_data(data)),
  ])
}

// Content data type ----------------------------------------------------------------------------

pub type ContentData {
  /// Post metadata
  PostData(
    /// Comments are stored as a list of `Comment`s.
    comments: List(Comment),
    /// Date string: This is decoded as a string, then recoded and decoded again to make sure it complies with ISO 8601.
    /// # Date published
    /// Stores the date on which the post was published.
    date_published: String,
    /// Date string: This is decoded as a string, then recoded and decoded again to make sure it complies with ISO 8601.
    /// # Date updated
    /// Stores the date on which the post was last updated.
    date_updated: String,
    /// Category this post belongs to
    category: String,
    /// Tags that belong to this post
    tags: List(String),
  )
  /// Page metadata
  PageData(
    /// In which menus this page should appear
    in_menus: List(Int),
  )
}

fn content_data_decoder() -> decode.Decoder(ContentData) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "post_data" -> {
      use comments <- decode.field("comments", decode.list(comment_decoder()))
      use date_published <- decode.field("date_published", decode.string)
      use date_updated <- decode.field("date_updated", decode.string)
      use category <- decode.field("category", decode.string)
      use tags <- decode.field("tags", decode.list(decode.string))
      decode.success(PostData(
        comments:,
        date_published:,
        date_updated:,
        category:,
        tags:,
      ))
    }
    "page_data" -> {
      use in_menus <- decode.field("in_menus", decode.list(decode.int))
      decode.success(PageData(in_menus:))
    }
    _ ->
      decode.failure(
        PostData(
          comments: [],
          date_published: "",
          date_updated: "",
          category: "",
          tags: [],
        ),
        "ContentData",
      )
  }
}

fn encode_content_data(content_data: ContentData) -> json.Json {
  case content_data {
    PostData(comments:, date_published:, date_updated:, category:, tags:) ->
      json.object([
        #("type", json.string("post_data")),
        #("comments", json.array(comments, encode_comment)),
        #("date_published", json.string(date_published)),
        #("date_updated", json.string(date_updated)),
        #("category", json.string(category)),
        #("tags", json.array(tags, json.string)),
      ])
    PageData(in_menus:) ->
      json.object([
        #("type", json.string("page_data")),
        #("in_menus", json.array(in_menus, json.int)),
      ])
  }
}

// Comment type ------------------------------------------------------------------------------
/// Comment
pub type Comment {
  Comment(
    /// Comment id
    id: Int,
    /// Just a name and email, nothing complicated.
    author: #(String, String),
    /// Storing the message as markdown is fine, makes it so that we don´t have to check that html
    message_md: String,
    /// A comment can be upvoted by a whole point, and downvoted one point, anonymously.
    score: Float,
  )
}

fn comment_decoder() -> decode.Decoder(Comment) {
  use id <- decode.field("id", decode.int)
  use author <- decode.field("author", {
    use a <- decode.field(0, decode.string)
    use b <- decode.field(1, decode.string)

    decode.success(#(a, b))
  })
  use message_md <- decode.field("message_md", decode.string)
  use score <- decode.field("score", decode.float)
  decode.success(Comment(id:, author:, message_md:, score:))
}

fn encode_comment(comment: Comment) -> json.Json {
  let Comment(id:, author:, message_md:, score:) = comment
  json.object([
    #("id", json.int(id)),
    #(
      "author",
      json.preprocessed_array([json.string(author.0), json.string(author.1)]),
    ),
    #("message_md", json.string(message_md)),
    #("score", json.float(score)),
  ])
}

// Vote type -------------------------------------------------------------------------------
/// Vote
/// A vote can be upvoted by a whole point, and downvoted one point, anonymously.
/// This is a simple enum that represents a vote being cast.
pub type Vote {
  DownVote(id: Int, post_permalink: String)
  UpVote(id: Int, post_permalink: String)
}

pub fn vote_decoder() -> decode.Decoder(Vote) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "down_vote" -> {
      use id <- decode.field("id", decode.int)
      use post_permalink <- decode.field("post_permalink", decode.string)
      decode.success(DownVote(id:, post_permalink:))
    }
    "up_vote" -> {
      use id <- decode.field("id", decode.int)
      use post_permalink <- decode.field("post_permalink", decode.string)
      decode.success(UpVote(id:, post_permalink:))
    }
    _ -> decode.failure(UpVote(0, ""), "Vote")
  }
}

pub fn encode_vote(vote: Vote) -> json.Json {
  case vote {
    DownVote(id:, post_permalink:) ->
      json.object([
        #("type", json.string("down_vote")),
        #("id", json.int(id)),
        #("post_permalink", json.string(post_permalink)),
      ])
    UpVote(id:, post_permalink:) ->
      json.object([
        #("type", json.string("up_vote")),
        #("id", json.int(id)),
        #("post_permalink", json.string(post_permalink)),
      ])
  }
}
// End of module.

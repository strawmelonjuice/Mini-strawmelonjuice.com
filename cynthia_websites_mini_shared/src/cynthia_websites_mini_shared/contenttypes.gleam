import gleam/dynamic/decode
import gleam/int
import gleam/string

pub type Minimal {
  Minimal(
    meta_title: String,
    meta_description: String,
    meta_kind: Int,
    meta_permalink: String,
    last_inserted_at: String,
    original_filename: String,
  )
}

pub fn minimal_aliased_decoder() -> decode.Decoder(Minimal) {
  use meta_title <- decode.field("meta_title", decode.string)
  use meta_description <- decode.field("meta_description", decode.string)
  use meta_kind_string <- decode.field("meta_kind", decode.string)
  let kind_transformer = fn(cont: fn(Int) -> decode.Decoder(Minimal)) -> decode.Decoder(
    Minimal,
  ) {
    let vid: Result(Int, decode.DecodeError) = case meta_kind_string {
      "page" -> Ok(0)
      "post" -> Ok(1)
      "custom " <> a -> {
        case int.parse(a) {
          Ok(f) -> Ok(f)
          Error(_) ->
            Error(
              decode.DecodeError(
                "Expected a valid custom kind",
                string.inspect(a),
                ["meta_kind"],
              ),
            )
        }
      }
      a ->
        Error(
          decode.DecodeError("Expected a valid kind", string.inspect(a), [
            "meta_kind",
          ]),
        )
    }
    case vid {
      Ok(meta_kind) -> cont(meta_kind)
      Error(_) ->
        decode.failure(
          Minimal(
            meta_title: "",
            meta_description: "",
            meta_kind: -1,
            meta_permalink: "",
            last_inserted_at: "",
            original_filename: "",
          ),
          "meta_kind",
        )
    }
  }
  use meta_kind <- kind_transformer
  use meta_permalink <- decode.field("meta_permalink", decode.string)
  use last_inserted_at <- decode.field("last_inserted_at", decode.string)
  use original_filename <- decode.field("original_filename", decode.string)
  decode.success(Minimal(
    meta_title:,
    meta_description:,
    meta_kind:,
    meta_permalink:,
    last_inserted_at:,
    original_filename:,
  ))
}

pub fn minimal_decoder() -> decode.Decoder(Minimal) {
  use meta_title <- decode.field("meta_title", decode.string)
  use meta_description <- decode.field("meta_description", decode.string)
  use meta_kind <- decode.field("meta_kind", decode.int)
  use meta_permalink <- decode.field("meta_permalink", decode.string)
  use last_inserted_at <- decode.field("last_inserted_at", decode.string)
  use original_filename <- decode.field("filename", decode.string)
  decode.success(Minimal(
    meta_title:,
    meta_description:,
    meta_kind:,
    meta_permalink:,
    last_inserted_at:,
    original_filename:,
  ))
}

import gleam/dynamic/decode

pub type Minimal {
  Minimal(
    meta_title: String,
    meta_description: String,
    meta_kind: Int,
    meta_permalink: String,
    last_inserted_at: String,
    filename: String,
  )
}

pub fn minimal_decoder() -> decode.Decoder(Minimal) {
  use meta_title <- decode.field("meta_title", decode.string)
  use meta_description <- decode.field("meta_description", decode.string)
  use meta_kind <- decode.field("meta_kind", decode.int)
  use meta_permalink <- decode.field("meta_permalink", decode.string)
  use last_inserted_at <- decode.field("last_inserted_at", decode.string)
  use filename <- decode.field("filename", decode.string)
  decode.success(Minimal(
    meta_title:,
    meta_description:,
    meta_kind:,
    meta_permalink:,
    last_inserted_at:,
    filename:,
  ))
}

import gleam/dynamic/decode
import gleam/fetch

pub type AnError {
  WebNotFound
  DecodeError(decode.DecodeError)
  DecodeErrorsPlural(List(decode.DecodeError))
  FetchError(fetch.FetchError)
}

import bungibindies/bun
import cynthia_websites_mini_shared/timestamps
import gleam/io
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

// Test timestamp parsing
pub fn timestamp_to_timestamp_test() {
  let times = #("2025-01-31T12:38:20Z", "2025-01-31T12:38:20+00:00")
  let results =
    #(timestamps.parse(times.0), timestamps.parse(times.1))
    |> io.debug()
  bun.deep_equals(results.1, results.0)
  |> should.be_true()
}

// Test timestamp formatting
pub fn timestamp_to_string_test() {
  let time = "2025-01-31T12:38:20.000Z"
  let result = timestamps.parse(time) |> timestamps.create()
  io.debug(result)
  result
  |> should.equal(time)
}

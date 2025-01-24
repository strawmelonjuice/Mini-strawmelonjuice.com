import gleam/io
import gleam/string
import gleeunit
import gleeunit/should

// todo: Timestamp conversion test

import cynthia_websites_mini_shared/timestamps

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

// Test timestamp conversion
pub fn timestamp_to_timestamp_test() {
  let time = "2025-01-22T12:12:07.001+01:00"
  let parsed = timestamps.parse(time)
  timestamps.create(parsed)
  |> should.equal(time)
}

// Test timestamp conversion
pub fn string_to_timestamp_test() {
  timestamps.parse("2025-01-24 20:51:03 GMT+0100")
  |> timestamps.create()
  |> should.equal("2025-01-24T20:51:03.000+01:00")
}

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
pub fn timestamp_to_test() {
  let time = "2025-01-22T12:12:07+0000"
  let parsed = timestamps.parse(time)
  timestamps.create(parsed)
  |> should.equal(time)
}

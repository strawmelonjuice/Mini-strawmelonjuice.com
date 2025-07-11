import plinth/javascript/date.{type Date}

/// Converts a timestamp from the ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
/// To a JavaScript 'date' object, accessible through Plinth.
@external(javascript, "./timestamps_ffi.ts", "parse")
pub fn parse(timestamp: String) -> Date

/// Converts a JavaScript 'date' object, accessible through Plinth
/// To a timestamp in the ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
/// This is the inverse of the `parse` function.
@external(javascript, "./timestamps_ffi.ts", "create")
pub fn create(date_object: Date) -> String {
  date_object |> date.to_iso_string()
}

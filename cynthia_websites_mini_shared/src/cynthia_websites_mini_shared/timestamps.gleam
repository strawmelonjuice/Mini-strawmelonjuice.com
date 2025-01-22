import plinth/javascript/date

/// Converts a timestamp from the ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
/// To a JavaScript 'date' object, accessible through Plinth.
@external(javascript, "./timestamps_ffi.mjs", "parse")
pub fn parse(timestamp: String) -> date.Date

/// Converts a JavaScript 'date' object, accessible through Plinth
/// To a timestamp in the ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
/// This is the inverse of the `parse` function.
pub fn create(date_object: date.Date) -> String {
  date.to_iso_string(date_object)
}

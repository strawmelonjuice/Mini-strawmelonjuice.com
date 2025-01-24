/// We use the moment.js library to parse and create timestamps.
/// This is because the JavaScript `Date` object is not capable of parsing timestamps in the ISO 8601 format reliably enough.
/// This means we also work with `Moment` objects!
pub type Moment

/// Converts a timestamp from the ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
/// To a JavaScript 'date' object, accessible through Plinth.
@external(javascript, "./timestamps_ffi.ts", "parse")
pub fn parse(timestamp: String) -> Moment

/// Converts a JavaScript 'date' object, accessible through Plinth
/// To a timestamp in the ISO 8601 date format (EG: 2025-01-22T12:12:07+0000)
/// This is the inverse of the `parse` function.
@external(javascript, "./timestamps_ffi.ts", "create")
pub fn create(date_object: Moment) -> String

/// Convert a moment object to an epoch timestamp in minutes.
@external(javascript, "./timestamps_ffi.ts", "to_minutes_since_epoch")
pub fn to_minutes_since_epoch(moment: Moment) -> Int

/// Convert minutes since epoch to a moment object.
@external(javascript, "./timestamps_ffi.ts", "from_minutes_since_epoch")
pub fn from_minutes_since_epoch(minutes: Int) -> Moment

/// Get the current time as a moment object.
@external(javascript, "./timestamps_ffi.ts", "rn")
pub fn rn() -> Moment

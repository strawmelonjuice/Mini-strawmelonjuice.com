// I would've used bungibindies->BunSQLite but it won't run in the browser... :c
//
// Instead FFI'ing to TS and using `sql.js`

import gleam/dynamic.{type Dynamic}
import gleam/javascript/array.{type Array}

pub fn init() {
  let db = new()
  // Prepare for usage
  db
  |> run(
    "CREATE TABLE IF NOT EXISTS `content_cache` (
      id TEXT PRIMARY KEY,
      html TEXT,
      last_update INTEGER
      );",
    [] |> array.from_list(),
  )
  db
  |> run(
    "CREATE TABLE IF NOT EXISTS `content` (id TEXT PRIMARY KEY, html TEXT, last_update: INTEGER);",
    [] |> array.from_list(),
  )
  db
}

pub type SQLiteDB

type BindParams =
  Array(#(String, String))

pub type QueryExecResult {
  QueryExecResult(columns: Array(String), values: Array(Array(Dynamic)))
}

@external(javascript, "./database_ffi.ts", "create")
fn new() -> SQLiteDB

@external(javascript, "./database_ffi.ts", "close")
pub fn close(db: SQLiteDB) -> Nil

@external(javascript, "./database_ffi.ts", "each")
pub fn each(
  db: SQLiteDB,
  sql: String,
  params: BindParams,
  callback: fn(#(string, Dynamic)) -> Nil,
  done: fn() -> Nil,
) -> Nil

@external(javascript, "./database_ffi.ts", "exec")
pub fn exec(db: SQLiteDB, sql: String, params: BindParams) -> QueryExecResult

@external(javascript, "./database_ffi.ts", "run")
pub fn run(db: SQLiteDB, sql: String, params: BindParams) -> Nil

// I would've used bungibindies->BunSQLite but it won't run in the browser... :c
//
// Instead FFI'ing to TS and using `sql.js`

import gleam/dynamic.{type Dynamic}
import gleam/javascript/array.{type Array}
import plinth/javascript/console

pub fn init() -> SQLiteDB {
  let db = new()
  console.log("Prepping database")
  // Prepare for usage
  exec(db, "PRAGMA journal_mode = WAL;", [] |> array.from_list())
  exec(db, "PRAGMA foreign_keys = ON;", [] |> array.from_list())

  console.log("Creating globalConfig table")
  db
  |> run(
    "
  CREATE TABLE IF NOT EXISTS globalConfig (
        site_name TEXT NOT NULL,
        site_colour TEXT NOT NULL,
        site_description TEXT NOT NULL,
        theme TEXT NOT NULL,
        theme_dark TEXT NOT NULL,
        layout TEXT NOT NULL
    );
",
    [] |> array.from_list(),
  )
  console.log("Creating content table")
  db
  |> run(
    "
  CREATE TABLE IF NOT EXISTS `content` (
    id TEXT PRIMARY KEY, 
    html TEXT, 
    last_update INTEGER
  );",
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

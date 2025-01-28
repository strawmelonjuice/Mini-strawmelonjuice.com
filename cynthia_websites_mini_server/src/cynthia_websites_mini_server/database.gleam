import bungibindies/bun/sqlite
import bungibindies/bun/sqlite/param_array
import plinth/node/process

pub fn create_database() -> sqlite.Database {
  let conn = sqlite.new(process.cwd() <> "/cache.db")
  conn
  |> sqlite.query("PRAGMA journal_mode = WAL;")
  |> sqlite.run(param_array.new())
  conn
  |> sqlite.query("PRAGMA foreign_keys = ON;")
  |> sqlite.run(param_array.new())
  conn
  |> sqlite.query(
    "CREATE TABLE IF NOT EXISTS globalConfig (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
      )",
  )
  |> sqlite.run(param_array.new())
  conn
  |> sqlite.query(
    "CREATE TABLE IF NOT EXISTS contentStore (
  content_id PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  extension TEXT NOT NULL,
  meta_title TEXT NOT NULL,
  meta_description TEXT NOT NULL,
  -- 0 = page, 1 = post
meta_kind INTEGER NOT NULL,
meta_layout TEXT NOT NULL,
meta_permalink TEXT NOT NULL,
  -- A JSON array of menu IDs
page_meta_menus TEXT NOT NULL,
  })",
  )
  |> sqlite.run(param_array.new())
  conn
}

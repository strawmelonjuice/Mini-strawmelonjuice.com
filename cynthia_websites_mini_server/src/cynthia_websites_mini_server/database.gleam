import bungibindies/bun/sqlite
import bungibindies/bun/sqlite/param_array
import plinth/node/process

pub fn create_database() -> sqlite.Database {
  let conn = sqlite.new(process.cwd() <> "/cache.db")
  conn
  |> sqlite.query(
    "CREATE TABLE IF NOT EXISTS data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT NOT NULL,
          html TEXT NOT NULL,
          created_at TEXT NOT NULL
      )",
  )
  |> sqlite.run(param_array.new())
  conn
}

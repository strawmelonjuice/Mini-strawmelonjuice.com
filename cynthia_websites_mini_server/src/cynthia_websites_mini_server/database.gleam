import bungibindies/bun
import bungibindies/bun/bunfile
import bungibindies/bun/sqlite
import bungibindies/bun/sqlite/param_array
import cynthia_websites_mini_shared/configtype
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import plinth/node/fs
import plinth/node/process

pub fn create_database(name: Option(String)) -> sqlite.Database {
  let db = {
    case name {
      None -> {
        deletecachedb()
        // sqlite.new(":memory:")
        sqlite.new(process.cwd() <> "/cache.db")
      }
      Some(n) -> sqlite.new(n)
    }
  }
  sqlite.exec(db, "PRAGMA journal_mode = WAL;")
  sqlite.exec(db, "PRAGMA foreign_keys = ON;")
  sqlite.exec(db, "PRAGMA temp_store = '2';")
  io.println("Database configured, creating table 1/4")
  sqlite.exec(
    db,
    "
    CREATE TABLE IF NOT EXISTS globalConfig (
        site_name TEXT NOT NULL,
        site_colour TEXT NOT NULL,
        site_description TEXT NOT NULL,
        theme TEXT NOT NULL,
        theme_dark TEXT NOT NULL
    )
  ",
  )
  io.println("Database configured, creating table 2/4")
  sqlite.exec(
    db,
    "
    CREATE TABLE IF NOT EXISTS contentStore (
      content_id INTEGER PRIMARY KEY AUTOINCREMENT,
      content TEXT NOT NULL,
      extension TEXT NOT NULL,
      meta_title TEXT NOT NULL,
      meta_description TEXT NOT NULL,
      -- 0 = page, 1 = post
      meta_kind INTEGER NOT NULL,
      meta_layout TEXT NOT NULL,
      meta_permalink TEXT NOT NULL,
      meta_original_file_path TEXT NOT NULL,
      last_inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
    )
  ",
  )

  io.println("Database configured, creating table 3/4")
  sqlite.exec(
    db,
    "
      CREATE TABLE IF NOT EXISTS pageMetaData (
        page_id INTEGER PRIMARY KEY NOT NULL,
        -- A JSON array of menu IDs
        meta_menus TEXT NOT NULL,
        FOREIGN KEY(page_id) REFERENCES contentStore(content_id)
      )
    ",
  )
  io.println("Database configured, creating table 4/4")
  sqlite.exec(
    db,
    "
      CREATE TABLE IF NOT EXISTS postMetaData (
        post_id INTEGER PRIMARY KEY NOT NULL,
        date_published TEXT NOT NULL,
        date_updated TEXT NOT NULL,
        FOREIGN KEY(post_id) REFERENCES contentStore(content_id)
      )
    ",
  )
  io.println("Database configured, tables created.")
  db
}

pub fn save_complete_config(
  db: sqlite.Database,
  conf: configtype.SharedCynthiaConfig,
) {
  // First, save the global config
  let statement =
    sqlite.prepare(
      db,
      "
      INSERT INTO globalConfig (
        site_name,
        site_colour,
        site_description,
        theme,
        theme_dark
      )
      VALUES (?, ?, ?, ?, ?);
    ",
    )

  let params =
    param_array.new()
    |> param_array.push(conf.global_site_name)
    |> param_array.push(conf.global_colour)
    |> param_array.push(conf.global_site_description)
    |> param_array.push(conf.global_theme)
    |> param_array.push(conf.global_theme_dark)
  sqlite.run(statement, params)
  // Now, save the content
  conf.content
  |> list.each(fn(content) {
    case content {
      configtype.ContentsPage(pg) -> {
        let statement =
          sqlite.prepare(
            db,
            "
            INSERT INTO contentStore (
              content,
              extension,
              meta_title,
              meta_description,
              meta_kind,
              meta_layout,
              meta_permalink,
              meta_original_file_path
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            RETURNING content_id;
          ",
          )

        let assert Ok(contents) = fs.read_file_sync(pg.filename)

        let assert Ok(extension) = pg.filename |> string.split(".") |> list.last

        let params =
          param_array.new()
          |> param_array.push(contents)
          |> param_array.push(extension)
          |> param_array.push(pg.title)
          |> param_array.push(pg.description)
          |> param_array.push(0)
          |> param_array.push(pg.layout)
          |> param_array.push(pg.permalink)
          |> param_array.push(
            pg.filename |> string.replace(process.cwd() <> "/content/", ""),
          )
        let assert Ok(contentinsertresult) =
          decode.run(sqlite.get(statement, params), content_insert_id_decoder())
        let id = contentinsertresult.content_id
        let statement =
          sqlite.prepare(
            db,
            "
            INSERT INTO pageMetaData (
              page_id,
              meta_menus
            )
            VALUES (?, ?)
          ",
          )

        let params =
          param_array.new()
          |> param_array.push(id)
          |> param_array.push(pg.page.menus)
        sqlite.run(statement, params)
      }
      configtype.ContentsPost(ps) -> {
        let statement =
          sqlite.prepare(
            db,
            "
            INSERT INTO contentStore (
              content,
              extension,
              meta_title,
              meta_description,
              meta_kind,
              meta_layout,
              meta_permalink
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
          ",
          )

        let assert Ok(contents) = fs.read_file_sync(ps.filename)

        let assert Ok(extension) = ps.filename |> string.split(".") |> list.last

        let params =
          param_array.new()
          |> param_array.push(contents)
          |> param_array.push(extension)
          |> param_array.push(ps.title)
          |> param_array.push(ps.description)
          |> param_array.push(1)
          |> param_array.push(ps.layout)
          |> param_array.push(ps.permalink)
        let id = sqlite.run(statement, params).last_insert_row_id
        let statement =
          sqlite.prepare(
            db,
            "
            INSERT INTO postMetaData (
              post_id,
              date_published,
              date_updated
            )
            VALUES (?, ?, ?)
          ",
          )

        let params =
          param_array.new()
          |> param_array.push(id)
          |> param_array.push(ps.post.date_posted)
          |> param_array.push(ps.post.date_updated)
        sqlite.run(statement, params)
      }
    }
  })
}

@external(javascript, "./utils/files_ffi.ts", "deletecachedb")
fn deletecachedb() -> Nil

type ContentInsertID {
  ContentInsertID(content_id: Int)
}

fn content_insert_id_decoder() -> decode.Decoder(ContentInsertID) {
  use content_id <- decode.field("content_id", decode.int)
  decode.success(ContentInsertID(content_id:))
}

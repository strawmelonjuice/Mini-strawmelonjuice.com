import bungibindies/bun/sqlite
import bungibindies/bun/sqlite/param_array
import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_shared/configtype
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleamy_lights/premixed
import plinth/node/fs
import plinth/node/process

pub fn create_database(name: Option(String)) -> sqlite.Database {
  let db = {
    case name {
      None -> {
        deletecachedb()
        // sqlite.new(":memory:")
        sqlite.new(files.path_join([process.cwd(), "/cache.db"]))
      }
      Some(n) -> sqlite.new(n)
    }
  }
  sqlite.exec(db, "PRAGMA journal_mode = WAL;")
  sqlite.exec(db, "PRAGMA foreign_keys = ON;")
  sqlite.exec(db, "PRAGMA temp_store = '2';")
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
          // 1: content
          |> param_array.push(contents)
          // 2: file extension
          |> param_array.push(extension)
          // 3: title
          |> param_array.push(pg.title)
          // 4: description
          |> param_array.push(pg.description)
          // 5: kind
          |> param_array.push(0)
          // 6: layout
          |> param_array.push(pg.layout)
          // 7: permalink
          |> param_array.push(pg.permalink)
          // 8: original file path
          |> param_array.push(
            pg.filename
            |> string.replace(files.path_join([process.cwd(), "/content/"]), ""),
          )
        let assert Ok(id) =
          decode.run(sqlite.get(statement, params), {
            use content_id <- decode.field("content_id", decode.int)
            decode.success(content_id)
          })
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
              meta_permalink,
              meta_original_file_path
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            RETURNING content_id;
          ",
          )

        let assert Ok(contents) = fs.read_file_sync(ps.filename)

        let assert Ok(extension) = ps.filename |> string.split(".") |> list.last

        let params =
          param_array.new()
          // 1: content
          |> param_array.push(contents)
          // 2: file extension
          |> param_array.push(extension)
          // 3: title
          |> param_array.push(ps.title)
          // 4: description
          |> param_array.push(ps.description)
          // 5: kind
          |> param_array.push(1)
          // 6: layout
          |> param_array.push(ps.layout)
          // 7: permalink
          |> param_array.push(ps.permalink)
          // 8: original file path
          |> param_array.push(
            ps.filename
            |> string.replace(files.path_join([process.cwd(), "/content/"]), ""),
          )
        let assert Ok(id) =
          decode.run(sqlite.get(statement, params), {
            use content_id <- decode.field("content_id", decode.int)
            decode.success(content_id)
          })
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

pub fn get__entire_global_config(
  db: sqlite.Database,
) -> Result(configtype.SharedCynthiaConfigGlobalOnly, List(decode.DecodeError)) {
  let statement =
    sqlite.prepare(
      db,
      "
      SELECT site_name, site_colour, site_description, theme, theme_dark
      FROM globalConfig
    ",
    )
  let row = sqlite.get(statement, param_array.new())
  let res =
    decode.run(row, {
      use site_name <- decode.field("site_name", decode.string)
      use site_colour <- decode.field("site_colour", decode.string)
      use site_description <- decode.field("site_description", decode.string)
      use theme <- decode.field("theme", decode.string)
      use theme_dark <- decode.field("theme_dark", decode.string)
      decode.success(configtype.SharedCynthiaConfigGlobalOnly(
        global_site_name: site_name,
        global_colour: site_colour,
        global_site_description: site_description,
        global_theme: theme,
        global_theme_dark: theme_dark,
      ))
    })
  case res |> result.is_error() {
    True -> {
      premixed.text_error_red(
        "The was an error decoding the global config from the database:"
        <> {
          res
          |> string.inspect
        },
      )
      |> io.println()
      Nil
    }
    False -> Nil
  }
  res
}

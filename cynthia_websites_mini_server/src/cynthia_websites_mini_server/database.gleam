import bungibindies/bun/sqlite
import bungibindies/bun/sqlite/param_array
import cynthia_websites_mini_server/utils/files
import cynthia_websites_mini_shared/configtype
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleamy_lights/premixed
import plinth/javascript/console
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
        category TEXT NOT NULL,
        tags TEXT NOT NULL,
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
          |> param_array.push({
            pg.page.menus
            |> list.map(fn(menu) { menu |> int.to_string })
            |> string.join(", ")
          })
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
              date_updated,
              category,
              tags
            )
            VALUES (?, ?, ?, ?, ?)
          ",
          )

        let params =
          param_array.new()
          |> param_array.push(id)
          |> param_array.push(ps.post.date_posted)
          |> param_array.push(ps.post.date_updated)
          |> param_array.push(ps.post.category)
          |> param_array.push({
            ps.post.tags
            |> list.map(fn(tag) { tag |> string.trim })
            |> string.join(", ")
          })
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
      |> console.log
      Nil
    }
    False -> Nil
  }
  res
}

pub fn get_content_by_filename(
  db: sqlite.Database,
  filename: String,
) -> Result(#(configtype.Contents, String), String) {
  let statement =
    sqlite.prepare(
      db,
      "
    SELECT content_id, content, extension, meta_title, meta_description, meta_kind, meta_layout, meta_permalink, meta_original_file_path FROM contentStore
    WHERE meta_original_file_path = ?
    ",
    )
  let params = param_array.new() |> param_array.push(filename)
  let row = sqlite.get(statement, params)
  let resu =
    decode.run(
      row,
      fn() {
        use content_id <- decode.field("content_id", decode.int)
        use content <- decode.field("content", decode.string)
        use meta_title <- decode.field("meta_title", decode.string)
        use meta_description <- decode.field("meta_description", decode.string)
        use meta_kind <- decode.field("meta_kind", decode.int)
        use meta_layout <- decode.field("meta_layout", decode.string)
        use meta_permalink <- decode.field("meta_permalink", decode.string)
        decode.success(#(
          // 0
          meta_kind,
          // 1
          content_id,
          // 2
          content,
          // 3
          meta_title,
          // 4
          meta_description,
          // 5
          meta_layout,
          // 6
          meta_permalink,
        ))
      }(),
    )
    |> result.map_error(fn(e) {
      "Error decoding content from the database:\n\n"
      <> string.inspect(e)
      <> "\n\n"
    })
  use res <- result.try(resu)
  let meta = case res.0 {
    0 -> {
      let statement =
        sqlite.prepare(
          db,
          "
        SELECT meta_menus FROM pageMetaData
        WHERE page_id = ?
        ",
        )
      let params = param_array.new() |> param_array.push(res.1)
      let row = sqlite.get(statement, params)
      let lres =
        decode.run(
          row,
          fn() {
            use meta_menus_str <- decode.field("meta_menus", decode.string)
            let meta_menus = case meta_menus_str |> string.is_empty() {
              True -> Ok([])
              False -> {
                meta_menus_str
                |> string.split(", ")
                |> list.map(fn(menu) { menu |> int.parse })
                |> result.all()
              }
            }
            let assert Ok(meta_menus) = meta_menus
              as "menu IDs from the database should be valid integers"
            decode.success(
              configtype.ContentsPage(configtype.Page(
                filename:,
                title: res.3,
                description: res.4,
                layout: res.5,
                permalink: res.6,
                page: configtype.ContentsPagePageData(meta_menus),
              )),
            )
          }(),
        )
        |> result.map_error(fn(e) {
          "Error decoding page metadata from the database:\n\n"
          <> string.inspect(e)
          <> "\n\n"
        })
      lres
    }
    1 -> {
      let statement =
        sqlite.prepare(
          db,
          "
        SELECT date_published, date_updated, tags, category FROM postMetaData
        WHERE post_id = ?
        ",
        )
      let params = param_array.new() |> param_array.push(res.1)
      let row = sqlite.get(statement, params)
      let lres =
        decode.run(
          row,
          fn() {
            use date_published <- decode.field("date_published", decode.string)
            use date_updated <- decode.field("date_updated", decode.string)
            use category <- decode.field("category", decode.string)
            use tagsstr <- decode.field("tags", decode.string)
            let tags = case tagsstr |> string.is_empty() {
              False -> {
                tagsstr
                |> string.split(", ")
                |> list.map(fn(tag) { tag |> string.trim })
              }
              True -> []
            }
            decode.success(
              configtype.ContentsPost(configtype.Post(
                filename:,
                title: res.3,
                description: res.4,
                layout: res.5,
                permalink: res.6,
                post: configtype.PostMetaData(
                  date_posted: date_published,
                  date_updated: date_updated,
                  category: category,
                  tags: tags,
                ),
              )),
            )
          }(),
        )
        |> result.map_error(fn(e) {
          "Error decoding post metadata from the database:\n\n"
          <> string.inspect(e)
          <> "\n\n"
        })
      lres
    }
    d -> {
      let a = "Unknown content kind: " <> string.inspect(d)
      Error(a)
    }
  }
  use metadata <- result.try(meta)
  Ok(#(metadata, res.2))
}

// Wasting lines just to do the same thing as above, but with a different query? Yeah. This might get more complex later on, so I'm keeping it separate.
pub fn get_content_by_permalink(db: sqlite.Database, permalink: String) {
  let statement =
    sqlite.prepare(
      db,
      "
    SELECT content_id, content, extension, meta_title, meta_description, meta_kind, meta_layout, meta_permalink, meta_original_file_path FROM contentStore
    WHERE meta_permalink = ?;
    ",
    )
  let params = param_array.new() |> param_array.push(permalink)
  let row = sqlite.get(statement, params)
  let resu =
    decode.run(
      row,
      fn() {
        use content_id <- decode.field("content_id", decode.int)
        use content <- decode.field("content", decode.string)
        use meta_title <- decode.field("meta_title", decode.string)
        use meta_description <- decode.field("meta_description", decode.string)
        use meta_kind <- decode.field("meta_kind", decode.int)
        use meta_layout <- decode.field("meta_layout", decode.string)
        use meta_original_file_path <- decode.field(
          "meta_original_file_path",
          decode.string,
        )
        decode.success(#(
          // 0
          meta_kind,
          // 1
          content_id,
          // 2
          content,
          // 3
          meta_title,
          // 4
          meta_description,
          // 5
          meta_layout,
          // 6
          meta_original_file_path,
        ))
      }(),
    )
    |> result.map_error(fn(e) {
      "Error decoding content from the database:\n\n"
      <> string.inspect(e)
      <> "\n\n"
    })
  let ft = fn(r: Result(a, String), f) {
    case r {
      Ok(a) -> f(a)
      Error(b) -> {
        console.warn(
          "Error retrieving '"
          <> permalink
          <> "' from database, assuming this means a 404: Not found. This is the error:\n"
          <> premixed.text_error_red(b),
        )
        Ok(None)
      }
    }
  }
  use res <- ft(resu)
  let meta = case res.0 {
    0 -> {
      let statement =
        sqlite.prepare(
          db,
          "
        SELECT meta_menus FROM pageMetaData
        WHERE page_id = ?
        ",
        )
      let params = param_array.new() |> param_array.push(res.1)
      let row = sqlite.get(statement, params)
      let lres =
        decode.run(
          row,
          fn() {
            use meta_menus_str <- decode.field("meta_menus", decode.string)
            let meta_menus = case meta_menus_str |> string.is_empty() {
              True -> Ok([])
              False -> {
                meta_menus_str
                |> string.split(", ")
                |> list.map(fn(menu) { menu |> int.parse })
                |> result.all()
              }
            }
            let assert Ok(meta_menus) = meta_menus
              as "menu IDs from the database should be valid integers"
            decode.success(
              configtype.ContentsPage(configtype.Page(
                filename: res.6,
                title: res.3,
                description: res.4,
                layout: res.5,
                permalink: permalink,
                page: configtype.ContentsPagePageData(meta_menus),
              )),
            )
          }(),
        )
        |> result.map_error(fn(e) {
          "Error decoding page metadata from the database:\n\n"
          <> string.inspect(e)
          <> "\n\n"
        })
      lres
    }
    1 -> {
      let statement =
        sqlite.prepare(
          db,
          "
        SELECT date_published, date_updated, tags, category FROM postMetaData
        WHERE post_id = ?
        ",
        )
      let params = param_array.new() |> param_array.push(res.1)
      let row = sqlite.get(statement, params)
      let lres =
        decode.run(
          row,
          fn() {
            use date_published <- decode.field("date_published", decode.string)
            use date_updated <- decode.field("date_updated", decode.string)
            use category <- decode.field("category", decode.string)
            use tagsstr <- decode.field("tags", decode.string)
            let tags = case tagsstr |> string.is_empty() {
              False -> {
                tagsstr
                |> string.split(", ")
                |> list.map(fn(tag) { tag |> string.trim })
              }
              True -> []
            }
            decode.success(
              configtype.ContentsPost(configtype.Post(
                filename: res.6,
                title: res.3,
                description: res.4,
                layout: res.5,
                permalink: permalink,
                post: configtype.PostMetaData(
                  date_posted: date_published,
                  date_updated: date_updated,
                  category: category,
                  tags: tags,
                ),
              )),
            )
          }(),
        )
        |> result.map_error(fn(e) {
          "Error decoding post metadata from the database:\n\n"
          <> string.inspect(e)
          <> "\n\n"
        })
      lres
    }
    d -> {
      let a = "Unknown content kind: " <> string.inspect(d)
      Error(a)
    }
  }
  use metadata <- result.try(meta)
  Ok(Some(#(metadata, res.2)))
}

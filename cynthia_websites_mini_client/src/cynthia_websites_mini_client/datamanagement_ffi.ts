import * as Gleam from "../../prelude";

import initSqlJs, { type Database } from "sql.js";
// At some point, Client-side-store will also be storing and retrieving in SQLite, on the browser.
// This was earlier delayed and replaced with a class as storage method, but that is but a temporary solution.
// If SQL.js does not work as expected, Postglide (Gleam wrapper around PGLite) should. However, that'd create a more persistent kind of storage (IndexedDB) that I do not want to tap into yet.
const SQL = await initSqlJs({
  locateFile: (file) => `https://sql.js.org/dist/${file}`,
});

interface flatGlobalConfig {
  global_theme: string;
  global_theme_dark: string;
  global_colour: string;
  global_site_name: string;
  global_site_description: string;
}

interface ClientStore {
  db: Database;
}

export function initialise(config: flatGlobalConfig): ClientStore {
  let obj: ClientStore = { db: new SQL.Database() };
  let sqlstr = `
      CREATE TABLE IF NOT EXISTS lasthash (
        hash TEXT NOT NULL PRIMARY KEY
      );
      INSERT INTO lasthash(hash) VALUES('/'); -- Default value
      CREATE TABLE IF NOT EXISTS content(
        html TEXT NOT NULL,
        original_filename TEXT NOT NULL PRIMARY KEY,
        meta_title TEXT NOT NULL,
        meta_description TEXT NOT NULL,
        meta_kind INTEGER NOT NULL,
        meta_permalink TEXT NOT NULL,
        last_inserted_at TEXT NOT NULL,
        meta_in_menus TEXT NOT NULL,
        meta_category TEXT NOT NULL,
        meta_post_published_at TEXT,
        meta_post_updated_at TEXT
      );
      CREATE TABLE IF NOT EXISTS globalconfig(
        theme TEXT NOT NULL,
        theme_dark TEXT NOT NULL,
        colour TEXT NOT NULL,
        site_name TEXT NOT NULL,
        site_description TEXT NOT NULL
      );
      DELETE FROM globalconfig;
      CREATE TABLE IF NOT EXISTS contentqueue(
        meta_title TEXT NOT NULL,
        meta_description TEXT NOT NULL,
        meta_kind INTEGER NOT NULL,
        meta_permalink TEXT NOT NULL,
        last_inserted_at TEXT NOT NULL,
        original_filename TEXT NOT NULL PRIMARY KEY
      );
      INSERT INTO globalconfig(theme, theme_dark, colour, site_name, site_description) VALUES('${config.global_theme}', '${config.global_theme_dark}', '${config.global_colour}', '${config.global_site_name}', '${config.global_site_description}');
      `;
  obj.db.run(sqlstr);
  return obj;
}

export function populate_global_config(
  store: ClientStore,
  config: flatGlobalConfig,
): void {
  let sql = `
      DELETE FROM globalconfig;
      INSERT INTO globalconfig(theme, theme_dark, colour, site_name, site_description) VALUES('${config.global_theme}', '${config.global_theme_dark}', '${config.global_colour}', '${config.global_site_name}', '${config.global_site_description}');
  `;
  store.db.run(sql);
}

export function get_config_item(store: ClientStore, item: string): string[] {
  let res = store.db.exec(`SELECT DISTINCT ${item}  FROM globalconfig`);
  let c = res[0].values[0][0];
  // console.log(item, ":", c);
  if (c == undefined) return [];
  return [c.toString()];
}

export function add_to_content_queue(
  store: ClientStore,
  content: {
    meta_title: string;
    meta_description: string;
    meta_kind: number;
    meta_permalink: string;
    last_inserted_at: string;
    original_filename: string;
  },
): void {
  let sql = `
      INSERT INTO contentqueue(meta_title, meta_description, meta_kind, meta_permalink, last_inserted_at, original_filename) VALUES('${content.meta_title}', '${content.meta_description}', ${content.meta_kind}, '${content.meta_permalink}', '${content.last_inserted_at}', '${content.original_filename}');
    `;
  store.db.run(sql);
}
export function add_to_content_store(
  store: ClientStore,
  content: {
    html: string;
    original_filename: string;
    meta_title: string;
    meta_description: string;
    meta_kind: number;
    meta_permalink: string;
    last_inserted_at: string;
    meta_in_menus: number[] | string[];
    meta_category?: string;
    // "" for pages
    last_updated_at: string;
    // "" for pages
    first_published_at: string;
  },
): void {
  let published =
    content.first_published_at == "" ? null : content.first_published_at;
  let updated =
    content.last_updated_at == "" ? published : content.last_updated_at;
  let stmt = store.db.prepare(
    `INSERT INTO content(
      html,
      original_filename, 
      meta_title,
      meta_description,
      meta_kind,
      meta_permalink, 
      last_inserted_at, 
      meta_in_menus, 
      meta_category,
      meta_post_published_at,
      meta_post_updated_at
    ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    `,
  );
  stmt.run([
    content.html,
    content.original_filename,
    content.meta_title,
    content.meta_description,
    content.meta_kind,
    content.meta_permalink,
    content.last_inserted_at,
    content.meta_in_menus.join(","),
    // This is supposed to only result in an empty string on pages, but currently, it's not being set anywhere.
    content.meta_category ?? "",
    published,
    updated,
  ]);
}
export function next_in_content_queue(
  store: ClientStore,
  cb: (
    arg0:
      | {
          meta_title: string;
          meta_description: string;
          meta_kind: number;
          meta_permalink: string;
          last_inserted_at: string;
          original_filename: string;
        }
      | undefined,
  ) => void,
) {
  let res = store.db.exec("SELECT * FROM contentqueue LIMIT 1;");
  if (res.length == 0) return undefined;
  let row = res[0].values[0];
  // If any of the values are null, return undefined
  if (row.includes(null)) {
    console.log("One or more queued content items are not readable. Skipping.");
    return undefined;
  }
  let content = {
    meta_title: row[0] as string,
    meta_description: row[1] as string,
    meta_kind: row[2] as number,
    meta_permalink: row[3] as string,
    last_inserted_at: row[4] as string,
    original_filename: row[5] as string,
  };
  // Check if the content is already in the store
  if (
    !(
      store.db.exec(
        "SELECT * FROM content WHERE original_filename = '" +
          content.original_filename +
          "';",
      ).length > 0
    )
  ) {
    cb(content);
  }
  // Delete from queue
  store.db.run(
    "DELETE FROM contentqueue WHERE original_filename = '" +
      content.original_filename +
      "';",
  );
}
// Dict(Int, List(#(String, String)))
export function get_menu_items(
  store: ClientStore,
): Map<number, [string, string]> {
  let content_store: {
    html: string;
    original_filename: string;
    meta_title: string;
    meta_description: string;
    meta_kind: string;
    meta_permalink: string;
    last_inserted_at: string;
    // For pages only, these are never strings.
    meta_in_menus: number[];
  }[] = [];
  {
    let res = store.db.exec("SELECT * FROM content WHERE meta_kind = 0;");
    if (res.length == 0) content_store = [];
    else {
      let rows = res[0].values;
      if (rows.length == 0) content_store = [];
      else {
        for (let row of rows) {
          // But what if there's only one menu item? or zero?
          let meta_in_menus = (row[7] as string)
            .split(",")
            .map((x) => parseInt(x));
          content_store.push({
            html: row[0] as string,
            original_filename: row[1] as string,
            meta_title: row[2] as string,
            meta_description: row[3] as string,
            meta_kind: (() => {
              switch (row[4]!.toString()) {
                case "0":
                  return "page";
                case "1":
                  return "post";
                default:
                  return "page";
              }
            })(),
            meta_permalink: row[5] as string,
            last_inserted_at: row[6] as string,
            meta_in_menus,
          });
        }
      }
    }
  }
  let v: string[][][] = [[], [], [], [], []];
  content_store.forEach((item, _) => {
    if (item.meta_kind == "post") return;
    if (item.meta_in_menus.includes(1))
      v[0].push([item.meta_title, item.meta_permalink]);
    if (item.meta_in_menus.includes(2))
      v[1].push([item.meta_title, item.meta_permalink]);
    if (item.meta_in_menus.includes(3))
      v[2].push([item.meta_title, item.meta_permalink]);
    if (item.meta_in_menus.includes(4))
      v[3].push([item.meta_title, item.meta_permalink]);
    if (item.meta_in_menus.includes(5))
      v[4].push([item.meta_title, item.meta_permalink]);
  });
  let res = new Map();
  res.set(1, v[0]);
  res.set(2, v[1]);
  res.set(3, v[2]);
  res.set(4, v[3]);
  res.set(5, v[4]);
  return res;
}

export function fetch_content_from_clientstore_by_permalink(
  store: ClientStore,
  permalink: string,
) {
  // Remove trailing slash from permalink if it exists
  permalink = permalink.replace(/\/$/, "");
  // console.log(list_all_permalinks_in_contentstore(store));
  const output = (() => {
    let res = store.db.exec(
      "SELECT * FROM content WHERE meta_permalink = '" + permalink + "';",
    );
    if (res.length == 0) return undefined;
    let row = res[0].values[0];
    if (row.includes(null)) return undefined;
    let content = {
      html: row[0] as string,
      original_filename: row[1] as string,
      meta_title: row[2] as string,
      meta_description: row[3] as string,
      meta_kind: (() => {
        switch (row[4]!.toString()) {
          case "0":
            return "page";
          case "1":
            return "post";
          default:
            return "page";
        }
      })(),
      meta_permalink: row[5] as string,
      last_inserted_at: row[6] as string,
      meta_in_menus: (row[7] as string).split(",").map((x) => parseInt(x)),
    };
    return content;
  })();
  if (output == undefined) return new Gleam.Error("");
  return new Gleam.Ok(output);
}

export function update_lasthash(store: ClientStore, hash: string) {
  store.db.run("DELETE FROM lasthash;");
  store.db.run(`INSERT INTO lasthash(hash) VALUES('${hash}');`);
}

export function get_lasthash(store: ClientStore) {
  let lel = (() => {
    let res = store.db.exec("SELECT * FROM lasthash;");
    if (res.length == 0) return "/";
    return res[0].values[0][0]?.toString();
  })();
  if (lel == undefined) return new Gleam.Error("");
  return new Gleam.Ok(lel);
}

export function list_all_permalinks_in_contentstore(
  store: ClientStore,
): string[] {
  let content_store: {
    html: string;
    original_filename: string;
    meta_title: string;
    meta_description: string;
    meta_kind: string;
    meta_permalink: string;
    last_inserted_at: string;
    meta_in_menus: string[] | number[];
  }[] = [];
  {
    let res = store.db.exec("SELECT * FROM content;");
    if (res.length == 0) content_store = [];
    else {
      let rows = res[0].values;
      if (rows.length == 0) content_store = [];
      else {
        for (let row of rows) {
          // But what if there's only one menu item? or zero?
          let meta_in_menus = (row[7] as string)
            .split(",")
            .map((x) => parseInt(x));
          content_store.push({
            html: row[0] as string,
            original_filename: row[1] as string,
            meta_title: row[2] as string,
            meta_description: row[3] as string,
            meta_kind: (() => {
              switch (row[4]!.toString()) {
                case "0":
                  return "page";
                case "1":
                  return "post";
                default:
                  return "page";
              }
            })(),
            meta_permalink: row[5] as string,
            last_inserted_at: row[6] as string,
            meta_in_menus,
          });
        }
      }
    }
  }
  let permalinks: string[] = [];
  content_store.forEach((item, _) => {
    permalinks.push(item.meta_permalink);
  });
  return permalinks;
}

export function fetch_post_list(
  store: ClientStore,
): { meta_permalink: string; meta_description: string; meta_title: string }[] {
  let res = store.db.exec(
    "SELECT meta_permalink,meta_description,meta_title,meta_in_menus,meta_category,meta_post_published_at,meta_post_updated_at FROM content WHERE meta_kind = 1;",
  );
  if (res.length == 0) return [];
  let rows = res[0].values;
  if (rows.length == 0) return [];
  let postlist = [];
  for (let row of rows) {
    postlist.push({
      meta_permalink: row[0] as string,
      meta_description: row[1] as string,
      meta_title: row[2] as string,
      meta_tags: (row[3] as string).split(",").map((x) => x.trim()),
      meta_category: row[4] as string,
      meta_date_posted: row[5] as string,
      meta_date_updated: row[6] as string,
    });
  }
  return postlist;
}

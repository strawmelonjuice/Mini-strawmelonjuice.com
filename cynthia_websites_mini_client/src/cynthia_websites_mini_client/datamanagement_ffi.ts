import * as Gleam from "../../prelude.ts";

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

class ClientStore {
  private db: Database;
  constructor(global_config: flatGlobalConfig) {
    console.log(global_config);
    // Creates database, this step might take some time.
    this.db = new SQL.Database();
    let sqlstr = `
      CREATE TABLE IF NOT EXISTS content(
        html TEXT NOT NULL,
        original_filename TEXT NOT NULL PRIMARY KEY,
        meta_title TEXT NOT NULL,
        meta_description TEXT NOT NULL,
        meta_kind INTEGER NOT NULL,
        meta_permalink TEXT NOT NULL,
        last_inserted_at TEXT NOT NULL,
        meta_in_menus TEXT NOT NULL
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
      INSERT INTO globalconfig(theme, theme_dark, colour, site_name, site_description) VALUES('${global_config.global_theme}', '${global_config.global_theme_dark}', '${global_config.global_colour}', '${global_config.global_site_name}', '${global_config.global_site_description}');
      `;
    this.db.run(sqlstr);
  }
  return_content_store_as_array() {
    let res = this.db.exec("SELECT * FROM content;");
    if (res.length == 0) return [];
    let rows = res[0].values;
    if (rows.length == 0) return [];
    let content_store: {
      html: string;
      original_filename: string;
      meta_title: string;
      meta_description: string;
      meta_kind: string;
      meta_permalink: string;
      last_inserted_at: string;
      meta_in_menus: number[];
    }[] = [];
    for (let row of rows) {
      // But what if there's only one menu item? or zero?
      let meta_in_menus = (row[7] as string).split(",").map((x) => parseInt(x));
      content_store.push({
        html: row[0] as string,
        original_filename: row[1] as string,
        meta_title: row[2] as string,
        meta_description: row[3] as string,
        meta_kind: (() => {
          switch (row[4].toString()) {
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
    return content_store;
  }
  add_to_content_queue(content: {
    meta_title: string;
    meta_description: string;
    meta_kind: number;
    meta_permalink: string;
    last_inserted_at: string;
    original_filename: string;
  }) {
    let sql = `
      INSERT INTO contentqueue(meta_title, meta_description, meta_kind, meta_permalink, last_inserted_at, original_filename) VALUES('${content.meta_title}', '${content.meta_description}', ${content.meta_kind}, '${content.meta_permalink}', '${content.last_inserted_at}', '${content.original_filename}');
    `;
    this.db.run(sql);
  }
  add_to_content_store(content: {
    html: string;
    original_filename: string;
    meta_title: string;
    meta_description: string;
    meta_kind: number;
    meta_permalink: string;
    last_inserted_at: string;
    meta_in_menus: number[];
  }) {
    let stmt = this.db.prepare(
      "INSERT INTO content(html, original_filename, meta_title, meta_description, meta_kind, meta_permalink, last_inserted_at, meta_in_menus) VALUES(?, ?, ?, ?, ?, ?, ?, ?);",
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
    ]);
  }
  content_queue_next(
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
    let res = this.db.exec("SELECT * FROM contentqueue LIMIT 1;");
    if (res.length == 0) return undefined;
    let row = res[0].values[0];
    // If any of the values are null, return undefined
    if (row.includes(null)) {
      console.log(
        "One or more queued content items are not readable. Skipping.",
      );
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
        this.db.exec(
          "SELECT * FROM content WHERE original_filename = '" +
            content.original_filename +
            "';",
        ).length > 0
      )
    ) {
      cb(content);
    }
    // Delete from queue
    this.db.run(
      "DELETE FROM contentqueue WHERE original_filename = '" +
        content.original_filename +
        "';",
    );
  }
  get_config_item(item: string): string[] {
    let res = this.db.exec(`SELECT DISTINCT ${item}  FROM globalconfig`);
    let c = res[0].values[0][0];
    // console.log(item, ":", c);
    if (c == undefined) return [];
    return [c.toString()];
  }
  update(global_config: flatGlobalConfig) {
    let sql = `
      DELETE FROM globalconfig;
      INSERT INTO globalconfig(theme, theme_dark, colour, site_name, site_description) VALUES('${global_config.global_theme}', '${global_config.global_theme_dark}', '${global_config.global_colour}', '${global_config.global_site_name}', '${global_config.global_site_description}');
  `;
    this.db.run(sql);
  }
}

export function initialise(config: flatGlobalConfig) {
  console.log("Initialising store with config", config);
  const store = new ClientStore(config);
  return store;
}

export function populate_global_config(
  store: ClientStore,
  config: flatGlobalConfig,
): void {
  store.update(config);
}

export function get_config_item(store: ClientStore, item: string): string[] {
  return store.get_config_item(item);
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
  store.add_to_content_queue(content);
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
    meta_in_menus: number[];
  },
): void {
  store.add_to_content_store(content);
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
  store.content_queue_next(cb);
}
// Dict(Int, List(#(String, String)))
export function get_menu_items(
  store: ClientStore,
): Map<number, [string, string]> {
  let v: string[][][] = [[], [], [], [], []];
  store.return_content_store_as_array().forEach((item, _) => {
    if (item.meta_kind == 1) return;
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

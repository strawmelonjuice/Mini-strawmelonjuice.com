//// Functions that run every 50ms

import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/datamanagement/database
import cynthia_websites_mini_client/dom
import gleam/bool
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/result
import plinth/browser/document

pub fn main(db: database.SQLiteDB) {
  let data = #(
    L1(0, db:, sub: L1o2(times: 0, db: db)),
    L2(0, db:),
    L3(0, db:),
    L4(0, db:),
    L5(0, db:),
  )
  let a = main_loop(data, 1)
  promise.resolve(a)
}

fn update_styles(db: database.SQLiteDB) {
  case dom.get_color_scheme() {
    "light" -> {
      datamanagement.pull_from_global_config_table("daisy_color_scheme", db)
      |> result.map_error(fn(_) {
        io.print_error("Error getting light color scheme from database")
      })
      |> result.unwrap("autumn")
      |> dom.set_data(document.body(), "theme", _)
    }
    "dark" -> {
      datamanagement.pull_from_global_config_table(
        "daisy_color_scheme_dark",
        db,
      )
      |> result.map_error(fn(_) {
        io.print_error("Error getting dark color scheme from database")
      })
      |> result.unwrap("coffee")
      |> dom.set_data(document.body(), "theme", _)
    }
    _ -> {
      Nil
    }
  }
}

fn populate_global_config_table(db) {
  datamanagement.populate_global_config_table(db)
}

// -- Loops and interval functions
// --
// -- These run the functions in the correct order and at the correct time
// -- However, they're also confusing and hard to read when working with the normal code
// -- So, they've been banished to the bottom of the file
// -- Beware, for all the code below this point is cursed
// --
type Ll =
  #(L1, L2, L3, L4, L5)

type L1o2 {
  L1o2(times: Int, db: database.SQLiteDB)
}

type L1 {
  L1(times: Int, db: database.SQLiteDB, sub: L1o2)
}

type L2 {
  L2(times: Int, db: database.SQLiteDB)
}

type L3 {
  L3(times: Int, db: database.SQLiteDB)
}

type L4 {
  L4(times: Int, db: database.SQLiteDB)
}

type L5 {
  L5(times: Int, db: database.SQLiteDB)
}

/// Functions that run every 800ms
fn level_1_2(params: L1o2) {
  populate_global_config_table(params.db)
  L1o2(params.times + 1, params.db)
}

/// Functions that run every 400ms
fn level_1(params: L1) {
  // -- Runs the sub function every 800ms
  let sub: L1o2 =
    params.times
    |> int.is_even()
    |> bool.guard(params.sub, fn() { level_1_2(params.sub) })
  L1(params.times + 1, params.db, sub:)
}

/// Functions that run every 300ms
fn level_2(params: L2) {
  L2(params.times + 1, params.db)
}

/// Functions that run every 200ms
fn level_3(params: L3) {
  update_styles(params.db)
  L3(params.times + 1, params.db)
}

/// Functions that run every 100ms
fn level_4(params: L4) {
  L4(params.times + 1, params.db)
}

fn level_5(params: L5) {
  L5(params.times + 1, params.db)
}

fn main_loop(datas: Ll, level: Int) {
  use _ <- promise.await(promise.wait(50))
  case level {
    1 -> {
      // console.log("Restarted realtime updater loop")
      // -- Funtions that run every 400ms
      #(
        level_1(datas.0),
        level_2(datas.1),
        level_3(datas.2),
        level_4(datas.3),
        level_5(datas.4),
      )
      |> main_loop(2)
    }
    2 -> {
      // -- In between (350ms)
      #(datas.0, datas.1, datas.2, datas.3, level_5(datas.4))
      |> main_loop(3)
    }
    3 -> {
      // -- Funtions that run every 300ms
      #(
        datas.0,
        level_2(datas.1),
        level_3(datas.2),
        level_4(datas.3),
        level_5(datas.4),
      )
      |> main_loop(4)
    }
    4 -> {
      // -- In between (250ms)
      #(datas.0, datas.1, datas.2, datas.3, level_5(datas.4))
      |> main_loop(5)
    }
    5 -> {
      // -- Funtions that run every 200ms
      #(datas.0, datas.1, level_3(datas.2), level_4(datas.3), level_5(datas.4))
      |> main_loop(6)
    }
    6 -> {
      // -- Funtions that run every 100ms
      #(datas.0, datas.1, datas.2, level_4(datas.3), level_5(datas.4))
      |> main_loop(7)
    }
    7 -> {
      // -- Very fast (50ms)
      #(datas.0, datas.1, datas.2, datas.3, level_5(datas.4))
      |> main_loop(1)
    }
    _ -> {
      promise.resolve(Nil)
    }
  }
}

//// Functions that run every 50ms

import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/datamanagement/clientstore
import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/pageloader
import cynthia_websites_mini_client/pottery/paints
import gleam/bool
import gleam/int
import gleam/javascript/promise
import gleam/result
import plinth/browser/document
import plinth/browser/window
import plinth/javascript/console

pub fn main(store: datamanagement.ClientStore) {
  let data = #(
    L1(0, store:, sub: L1o2(times: 0, store:, one_of: 0)),
    L2(0, store:),
    L3(0, store:),
    L4(0, store:),
    L5(0, store:),
  )
  let a = main_loop(data, 1)
  promise.resolve(a)
}

fn hashcheck(store: datamanagement.ClientStore) {
  let assert Ok(hash) = window.get_hash()
  let assert Ok(last_hash) = clientstore.get_lasthash(store)
  case hash == last_hash {
    True -> Nil
    False -> {
      case pageloader.now(store) {
        Ok(_) -> datamanagement.update_lasthash(store, hash)
        Error(_) -> Nil
      }
    }
  }
}

fn update_styles(store: datamanagement.ClientStore) {
  paints.get_sytheme(store)
  |> result.map(fn(theme) { theme.daisy_ui_theme_name })
  |> result.unwrap("autumn")
  |> dom.set_data(document.body(), "theme", _)
}

fn populate_global_config_table(store) {
  datamanagement.populate_global_config_table(store)
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
  L1o2(times: Int, one_of: Int, store: datamanagement.ClientStore)
}

type L1 {
  L1(times: Int, store: datamanagement.ClientStore, sub: L1o2)
}

type L2 {
  L2(times: Int, store: datamanagement.ClientStore)
}

type L3 {
  L3(times: Int, store: datamanagement.ClientStore)
}

type L4 {
  L4(times: Int, store: datamanagement.ClientStore)
}

type L5 {
  L5(times: Int, store: datamanagement.ClientStore)
}

/// Functions that run every 800ms
fn level_1_2(params: L1o2) {
  let one_of = case params.one_of {
    // Run this subfunction every 6400ms
    7 | 15 | 23 | 31 -> {
      // populate_global_config_table(params.store)
      int.add(params.one_of, 1)
    }
    14 | 30 -> {
      // Run this subfunction every 12800ms (12.8s)
      console.log("Rebuilding content queue to update content.")
      datamanagement.requeue_content(params.store)
      int.add(params.one_of, 1)
    }
    // On the last iteration, reset to 1
    33 -> 1
    // Otherwise, just add 1
    p -> int.add(p, 1)
  }
  L1o2(..params, times: params.times + 1, one_of:)
}

/// Functions that run every 400ms
fn level_1(params: L1) {
  datamanagement.render_next_of_content_queue(params.store)
  // -- Runs the sub function every 800ms
  let sub: L1o2 =
    params.times
    |> int.is_even()
    |> bool.guard(params.sub, fn() { level_1_2(params.sub) })
  L1(params.times + 1, params.store, sub:)
}

/// Functions that run every 300ms
fn level_2(params: L2) {
  L2(params.times + 1, params.store)
}

/// Functions that run every 200ms
fn level_3(params: L3) {
  update_styles(params.store)
  L3(params.times + 1, params.store)
}

/// Functions that run every 100ms
fn level_4(params: L4) {
  L4(params.times + 1, params.store)
}

fn level_5(params: L5) {
  case params.times > 6 {
    True -> hashcheck(params.store)
    False -> Nil
  }
  L5(..params, times: params.times + 1)
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

// I copied from the examples again to use as boilerplate... See https://github.com/lustre-labs/lustre/blob/main/examples/03-effects/01-http-requests/src/app.gleam for reference until nothing is recognisable.

// IMPORTS ---------------------------------------------------------------------

import cynthia_websites_mini_client/dom
import cynthia_websites_mini_client/messages.{
  type Msg, ApiReturnedData, UserNavigateTo,
}
import cynthia_websites_mini_client/model_type.{type Model, Model}
import cynthia_websites_mini_client/utils
import cynthia_websites_mini_client/view
import cynthia_websites_mini_shared/configtype
import cynthia_websites_mini_shared/contenttypes
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/effect.{type Effect}
import plinth/browser/window

import modem
import rsvp

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view.main)
  let assert Ok(_) = lustre.start(app, "#viewable", Nil)

  Nil
}

fn init(_) -> #(Model, Effect(Msg)) {
  let effects =
    effect.batch([fetch_all(ApiReturnedData), modem.init(on_url_change)])
  let initial_path = case window.get_hash() {
    Ok("") | Error(..) -> {
      dom.set_hash("/")
      "/"
    }
    Ok(f) -> f
  }
  let model = Model(initial_path, None, dict.new(), Ok(Nil))

  #(model, effects)
}

// Effect handlers --------------------------------------------------------------
/// On url change: (Obviously) is triggered on url change, this is useful for intercepting the url hash change on in-site-navigation, that Cynthia uses.
fn on_url_change(uri: Uri) -> Msg {
  let assert Ok(#(_, d)) =
    uri
    |> uri.to_string
    |> string.split_once("#")

  messages.UserNavigateTo(d)
}

/// Fetches data from server side
fn fetch_all(
  on_response handle_response: fn(Result(configtype.CompleteData, rsvp.Error)) ->
    msg,
) -> Effect(msg) {
  let url = utils.phone_home_url() <> "/site.json"
  let decoder = configtype.complete_data_decoder()
  let handler = rsvp.expect_json(decoder, handle_response)

  // When we call `rsvp.get` that doesn't immediately make the request. Instead,
  // it returns an effect that we give to the runtime to handle for us.
  rsvp.get(url, handler)
}

// UPDATE ----------------------------------------------------------------------

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigateTo(path) -> {
      #(Model(..model, path:), effect.none())
    }
    ApiReturnedData(data) -> {
      case data {
        Error(e) -> {
          let error_message =
            "Cynthia Client failed "
            <> case e {
              rsvp.UnhandledResponse(s) ->
                "to handle the server's response: '" <> string.inspect(s) <> "'"
              rsvp.HttpError(_) | rsvp.NetworkError -> "to connect to server."
              rsvp.JsonError(s) ->
                "to decode response: '" <> string.inspect(s) <> "'"
              _ -> " to load this site."
            }
          #(Model(..model, status: Error(error_message)), effect.none())
        }
        Ok(new) -> {
          let computed_menus = compute_menus(new.content, model)
          let complete_data = Some(new)
          let status = Ok(Nil)
          let path = model.path
          #(
            Model(path:, complete_data:, computed_menus:, status:),
            effect.none(),
          )
        }
      }
    }
  }
}

// Helper function to compute menus --------------------------------------------------------
fn compute_menus(content: List(contenttypes.Content), model: Model) {
  let menu_s_available =
    content
    |> list.filter_map(fn(alls) {
      case alls.data {
        contenttypes.PageData(soms) -> Ok(soms)
        _ -> Error(Nil)
      }
    })
    |> list.flatten()
    |> list.unique()
    |> list.sort(int.compare)
  add_each_menu(menu_s_available, model.computed_menus, content)
}

// This is actually where the real magic happens
fn add_each_menu(
  rest: List(Int),
  gotten: dict.Dict(Int, List(#(String, String))),
  items: List(contenttypes.Content),
) -> dict.Dict(Int, List(#(String, String))) {
  case rest {
    [] -> gotten
    [current_menu, ..rest] -> {
      let hits =
        list.filter_map(items, fn(item) {
          case item.data {
            contenttypes.PageData(m) -> {
              case m |> list.contains(current_menu) {
                True -> {
                  Ok(#(item.title, item.permalink))
                }
                False -> Error(Nil)
              }
            }
            _ -> Error(Nil)
          }
        })
      dict.insert(gotten, current_menu, hits)
      |> add_each_menu(rest, _, items)
    }
  }
}

import cynthia_websites_mini_shared/configtype
import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type Model {
  Model(
    /// Where are we
    path: String,
    /// Complete data that makes up the site. This is all that the server serves up.
    complete_data: Option(configtype.CompleteData),
    /// Menu's stored readily  for themes to pick up.
    /// Structure:
    /// Dict(which_menu: Int, List(#(to, from)))
    computed_menus: Dict(Int, List(#(String, String))),
    /// Status
    /// Allows us to trigger the error page from the update function, without the need for more variants of Model.
    ///
    /// Normally this is `Ok(Nil)`
    /// On error this is `Error(error_message: String)`
    status: Result(Nil, String),
  )
}

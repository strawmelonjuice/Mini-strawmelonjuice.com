import bungibindies
import gleam/io
import gleamy_lights/premixed

pub fn main() {
  case bungibindies.runs_in_bun() {
    Ok(_) -> Nil
    Error(_) ->
      io.println(premixed.text_red(
        "Error: Cynthia mini needs to run in Bun! Try installing and running it with Bun instead.",
      ))
  }
  io.println(premixed.text_green("Hello from cynthia_websites_mini_server!"))
}

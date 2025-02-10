import plinth/javascript/console

@external(javascript, "./prompts_ffi.ts", "promptForInput")
fn prompt(message: String) -> Result(String, Nil)

pub fn for_confirmation(message: String, default: Bool) -> Bool {
  let suffix = case default {
    True -> " [Y/n]"
    False -> " [y/N]"
  }
  let response = prompt(message <> suffix)
  case response {
    Ok("y") | Ok("Y") -> True
    Ok("n") | Ok("N") -> False
    Error(Nil) -> default
    _ -> {
      console.error("Invalid response. Please enter 'y' or 'n'.")
      for_confirmation(message, default)
    }
  }
}

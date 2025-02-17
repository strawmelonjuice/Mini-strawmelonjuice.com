import cynthia_websites_mini_client/datamanagement
import cynthia_websites_mini_client/pottery/ceramics
import cynthia_websites_mini_client/realtime

pub fn main() {
  ceramics.loading_screen()
  // Initialise database
  let clientstore = datamanagement.init()
  let _ = realtime.main(clientstore)
  datamanagement.update_content_queue(clientstore)
  todo as "priority loader not implemented yet!"
}

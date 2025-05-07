import cynthia_websites_mini_shared/configtype
import rsvp

pub type Msg {
  ApiReturnedData(Result(configtype.CompleteData, rsvp.Error))
  UserNavigateTo(String)
}

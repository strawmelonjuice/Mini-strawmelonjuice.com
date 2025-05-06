import cynthia_websites_mini_server/config as config_module
import cynthia_websites_mini_shared/configtype
import gleam/option.{type Option, None}
import javascript/mutable_reference

pub type MutableModel =
  mutable_reference.MutableReference(MutableModelContent)

pub fn new() -> MutableModel {
  mutable_reference.new(
    MutableModelContent(cached_response: None, config: {
      config_module.capture_config()
    }),
  )
}

pub type MutableModelContent {
  MutableModelContent(
    cached_response: Option(String),
    config: configtype.SharedCynthiaConfigGlobalOnly,
  )
}

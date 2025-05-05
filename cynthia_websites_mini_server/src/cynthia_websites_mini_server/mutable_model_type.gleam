import gleam/option.{type Option}
import javascript_mutable_reference

fn new(){
	 mutable_reference.new(MutableModel(None))
}

type MutableModel {
	MutableModel (
		cachedresponse: Option(String)

	)
}

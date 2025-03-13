import * as Gleam from "../../prelude";
export function gleam_to_nullable(option: { 0?: any }) {
  if (option[0] !== null && option[0] !== "undefined") {
    return option[0];
  } else {
    return null;
  }
}

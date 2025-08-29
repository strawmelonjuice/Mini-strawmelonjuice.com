import { Ok as GleamOk, Error as GleamError } from "../../../../prelude";

export function badges_getter() {
  let badges = window["strawmelonjuice badges"];
  if (badges) {
    return new GleamOk(badges);
  } else {
    return new GleamError(null);
  }
}

export function badges_saver(badges: unknown) {
  window["strawmelonjuice badges"] = badges;
  return badges;
}

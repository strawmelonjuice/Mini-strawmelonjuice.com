import { Ok as GleamOk, Error as GleamError } from "../../../../prelude";

export function steal_footer(): string {
  const footer = document.querySelector("#cynthiafooter");
  const paragraph_in_footer = footer?.querySelector("p");
  footer?.classList.add("hidden");
  return paragraph_in_footer?.innerHTML || "";
}

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

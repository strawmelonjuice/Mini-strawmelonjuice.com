// Bun implements the prompt api, like a browser would.

import { Ok as GleamOk, Error as GleamError } from "../../../prelude";
export function promptForInput(
  msg: string,
): GleamOk<string, unknown> | GleamError<unknown, null> {
  const answer = prompt(msg);
  console.log(answer);
  if (answer === null) {
    return new GleamError(null);
  } else {
    return new GleamOk(answer);
  }
}

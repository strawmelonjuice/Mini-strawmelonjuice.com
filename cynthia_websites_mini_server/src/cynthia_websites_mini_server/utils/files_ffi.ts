import fs from "node:fs";
export function exists(a: string): boolean {
  return fs.existsSync(a);
}

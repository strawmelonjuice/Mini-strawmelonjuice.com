import fs from "node:fs";
import path from "node:path";
export function exists(a: string): boolean {
  return fs.existsSync(a);
}
export function deletecachedb() {
  if (fs.existsSync(path.join(process.cwd(), "./cache.db")))
    fs.unlinkSync(path.join(process.cwd(), "./cache.db"));
}

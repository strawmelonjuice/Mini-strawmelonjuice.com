import fs from "node:fs";
import path from "node:path";
import type { List } from "../../../prelude";
export function exists(a: string): boolean {
  return fs.existsSync(a);
}
export function deletecachedb() {
  if (fs.existsSync(path.join(process.cwd(), "./cache.db")))
    fs.unlinkSync(path.join(process.cwd(), "./cache.db"));
}

export function path_join(paths: List<string>): string {
  return path.join(...paths.toArray());
}

export function path_normalize(p: string): string {
  return path.normalize(p);
}

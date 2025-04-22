import { expect, test } from "bun:test";

process.chdir(__dirname + "/..");

test("server gleeunit tests (best to be ran with `bun run test server`)", () => {
  expect(
    Bun.spawnSync({
      cmd: [process.argv0, "run", "test", "server"],
    }).success,
  ).toBe(true);
});

import { expect, test } from "bun:test";

process.chdir(__dirname + "/..");

test("client gleeunit tests (best to be ran with `bun run test client`)", () => {
  expect(
    Bun.spawnSync({
      cmd: [process.argv0, "run", "test", "client"],
    }).success,
  ).toBe(true);
});

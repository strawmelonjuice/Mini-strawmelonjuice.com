const tailwindconfig: import("tailwindcss").Config = {
  daisyui: {
    themes: ["autumn", "coffee"],
    darkMode: ["selector", '[data-theme="night"]'],
  },
  content: [
    "./cynthia_websites_mini_client/**/*.gleam",
    "./cynthia_websites_mini_server/src/cynthia_websites_mini_server/static_routes.gleam",
    "./cynthia_websites_mini_shared/src/cynthia_websites_mini_shared/ui.gleam",
  ],
  theme: {
    extend: {},
  },
  plugins: [require("daisyui")],
};

if (process.argv[2].toLowerCase() == "clean") {
  console.log("Cleaning up...");
  {
    let a = Bun.spawnSync({
      cmd: ["gleam", "clean"],
      cwd: "./cynthia_websites_mini_client/",
      // stderr: "inherit",
    }).success;
    let b = Bun.spawnSync({
      cmd: ["gleam", "clean"],
      cwd: "./cynthia_websites_mini_server/",
      // stderr: "inherit",
    }).success;
    let c = Bun.spawnSync({
      cmd: ["rm", "-rf", "./dist"],
    });
    let d = Bun.spawnSync({
      cmd: ["rm", "-rf", "./node_modules/"],
    });
    let e = Bun.spawnSync({
      cmd: [
        "rm",
        "-rf",
        "./cynthia_websites_mini_server/src/client_code_generated_ffi.ts",
      ],
    });
    if (a && b && c && d && e) {
      console.log("cleared.");
      process.exit(0);
    } else {
      console.error("cleaning failed, aborting");
      process.exit(1);
    }
  }
} else if (process.argv[2].toLowerCase() == "fmt") {
  let a = Bun.spawnSync({
    cmd: ["gleam", "format"],
    cwd: "./cynthia_websites_mini_server/",
    stdout: "inherit",
    stderr: "inherit",
  }).success;
  let b = Bun.spawnSync({
    cmd: ["gleam", "format"],
    cwd: "./cynthia_websites_mini_client/",
    stdout: "inherit",
    stderr: "inherit",
  }).success;
  if (a && b) {
    console.log("formatting successful.");
    process.exit(0);
  } else {
    console.error("formatting failed, aborting");
    process.exit(1);
  }
}
console.log("Checking Bun dependencies...");
Bun.spawnSync({
  cmd: ["bun", "install"],
  stdout: "inherit",
  stderr: "inherit",
});
console.log("Building and bundling client code...");
{
  let o = Bun.spawnSync({
    cmd: ["gleam", "build"],
    cwd: "./cynthia_websites_mini_client/",
    stderr: "inherit",
  }).success;
  if (o) {
  } else {
    console.error("client build failed, aborting");
    process.exit(1);
  }
  await Bun.write(
    "./cynthia_websites_mini_client/build/dev/javascript/cynthia_websites_mini_client/cynthia_websites_mini_client.ts",
    `import { main } from "./cynthia_websites_mini_client.mjs";document.addEventListener("DOMContentLoaded", main());`,
  );
  // Bundle client code to a single file
  await Bun.build({
    entrypoints: [
      "./cynthia_websites_mini_client/build/dev/javascript/cynthia_websites_mini_client/cynthia_websites_mini_client.ts",
    ],
    outdir: "./cynthia_websites_mini_client/build/bundled/",
    minify: {
      whitespace: true,
      syntax: true,
      identifiers: false,
    },

    target: "browser",
  });
  let css = "/* Something has gone wrong building this CSS. */";

  const postcss = require("postcss");
  const tailwindcss = require("tailwindcss");

  const sourceCSS = "@tailwind base; @tailwind components; @tailwind utilities";
  const config = {
    presets: [tailwindconfig],
  };
  await postcss([tailwindcss(config)])
    .process(sourceCSS)
    .then((genned_css: { css: string }) => {
      // `css` is a string of the compiled CSS.
      css = genned_css.css;
    })
    .catch((err: any) => {
      console.error(err);
    });
  const client_styles = JSON.stringify(css);

  const client_script = JSON.stringify(
    await Bun.file(
      "./cynthia_websites_mini_client/build/bundled/cynthia_websites_mini_client.js",
    ).text(),
  );
  console.log("Putting client script and styles into server code...");
  Bun.file(
    "./cynthia_websites_mini_server/src/client_code_generated_ffi.ts",
  ).write(
    `export function client_script() { return ${client_script}; }
export function client_styles() { return ${client_styles}; }`,
  );
}
console.log("Building and bundling server code...");
{
  // Compile the server code to JavaScript
  let o = Bun.spawnSync({
    cmd: ["gleam", "build"],
    cwd: "./cynthia_websites_mini_server/",
    stderr: "inherit",
  }).success;
  // Check if the build was successful
  if (o) {
  } else {
    console.error("server build failed, aborting");
    process.exit(1);
  }
  // Create entry point for the server
  await Bun.write(
    "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
    `import { main } from "./cynthia_websites_mini_server.mjs";main();`,
  );
}
console.log("Prepping code successfully completed.");
if (process.argv[2].toLowerCase() == "gleam") {
  const argumens = process.argv.slice(3);
  console.log("Running" + (" gleam " + argumens.join(" ")));
  let a = Bun.spawnSync({
    cmd: ["gleam", ...argumens],
    cwd: "./cynthia_websites_mini_server/",
    stdout: "inherit",
    stderr: "inherit",
  }).success;
  let b = Bun.spawnSync({
    cmd: ["gleam", ...argumens],
    cwd: "./cynthia_websites_mini_client/",
    stdout: "inherit",
    stderr: "inherit",
  }).success;
  if (a && b) {
    console.log("gleam command successful.");
    process.exit(0);
  } else {
    console.error("gleam command failed, aborting");
    process.exit(1);
  }
} else if (process.argv[2].toLowerCase() == "bundle") {
  console.log("Compiling all to single package...");
  {
    // Bundle code to dist
    await Bun.build({
      minify: false,
      target: "bun",
      entrypoints: [
        "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
      ],
      outdir: "./dist",
    });
    console.log("Bundling completed.");
    process.exit(0);
  }
} else if (process.argv[2].toLowerCase() == "run") {
  console.log("Running server...");
  {
    // Run the server
    Bun.spawnSync({
      cmd: [
        "bun",
        "./cynthia_websites_mini_server/build/dev/javascript/cynthia_websites_mini_server/cynthia_websites_mini_server.ts",
      ],
      stdout: "inherit",
      stderr: "inherit",
      stdin: "inherit",
    });
  }
} else if (process.argv[2].toLowerCase() == "test") {
  console.log("Running tests...");
  {
    // Run the tests
    console.log("Running tests for server:");
    let a = Bun.spawnSync({
      cmd: ["gleam", "test"],
      cwd: "./cynthia_websites_mini_server/",
      stdout: "inherit",
      stderr: "inherit",
    }).success;
    console.log("Running tests for client:");
    let b = Bun.spawnSync({
      cmd: ["gleam", "test"],
      cwd: "./cynthia_websites_mini_client/",
      stdout: "inherit",
      stderr: "inherit",
    }).success;
    if (a && b) {
      console.log("tests successful.");
      process.exit(0);
    } else {
      console.error("tests failed, aborting");
      process.exit(1);
    }
  }
} else if (process.argv[2].toLowerCase() == "check") {
  console.log("Checking code...");
  {
    // Check the code
    console.log("Checking server code:");
    let a = Bun.spawnSync({
      cmd: ["gleam", "check"],
      cwd: "./cynthia_websites_mini_server/",
      stdout: "inherit",
      stderr: "inherit",
    }).success;
    console.log("Checking client code:");
    let b = Bun.spawnSync({
      cmd: ["gleam", "check"],
      cwd: "./cynthia_websites_mini_client/",
      stdout: "inherit",
      stderr: "inherit",
    }).success;
    if (a && b) {
      console.log("checks successful.");
      process.exit(0);
    } else {
      console.error("checks failed, aborting");
      process.exit(1);
    }
  }
} else {
  console.log("To build, run: bun ./build.ts bundle");
  console.log("To run, run: bun ./build.ts run");
  console.log("To test, run: bun ./build.ts test");
  console.log("To check, run: bun ./build.ts check");
  console.log("To clean, run: bun ./build.ts clean");
  console.log("To format, run: bun ./build.ts fmt");
  console.log(
    "To run gleam commands on both ends, run: bun ./build.ts gleam <subcommand>",
  );
}

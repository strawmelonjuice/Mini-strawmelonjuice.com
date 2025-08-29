#!/usr/bin/env bun

import { $, spawn, spawnSync } from "bun";
import { fstat } from "fs";
import { existsSync } from "fs";
import { cp, readFile, writeFile } from "fs/promises";
import path, { join } from "path";

const repoUrl = "https://github.com/CynthiaWebsiteEngine/Mini";
const branch = "main";
const patchesDir = "patches/files";
const specialPatchesDir = "patches/special";
const cloneDir = "patch-target";

async function applyPatches() {
  // Delete the cloneDir, but if it contains a test subdirectory, make sure that'll be preserved and restored after cloning.
  if (existsSync(path.join(cloneDir, "test"))) {
    await $`mv ${cloneDir}/test ./test`;
  }
  await $`rm -rf ${cloneDir}`;

  console.log("Cloning the original repository...");
  await $`git clone --branch ${branch} ${repoUrl} ${cloneDir}`;

  if (existsSync("./test")) {
    await $`mv ./test ${cloneDir}/test`;
  }

  // Run bun install in the clone directory
  console.log("Installing dependencies...");
  spawn(["bun", "install"], {
    cwd: cloneDir,
    stdout: "inherit",
    stderr: "inherit",
  });


  console.log("Applying file patches...");
  await copyPatches(patchesDir, cloneDir);

  console.log("Applying special JSON patches...");
  const patchedFiles = await applySpecialPatches(specialPatchesDir, cloneDir);

  console.log("Showing git diff for patched files...");
  await showGitDiff(patchedFiles, cloneDir);

  console.log("Removing remote from the cloned repository...");
  await $`git -C ${cloneDir} remote remove origin`;

  console.log("Patches applied successfully.");
}

async function copyPatches(sourceDir: string, targetDir: string) {
  const { readdir, stat } = await import("fs/promises");

  async function copyRecursive(src: string, dest: string) {
    const entries = await readdir(src, { withFileTypes: true });
    for (const entry of entries) {
      const srcPath = join(src, entry.name);
      const destPath = join(dest, entry.name);

      if (entry.isDirectory()) {
        await $`mkdir -p ${destPath}`;
        await copyRecursive(srcPath, destPath);
      } else {
        await cp(srcPath, destPath);
      }
    }
  }

  await copyRecursive(sourceDir, targetDir);
}

async function applySpecialPatches(patchesDir: string, targetDir: string) {
  const { readdir } = await import("fs/promises");
  const patchFiles = await readdir(patchesDir);
  const patchedFiles = [];

  for (const patchFile of patchFiles) {
    const patchPath = join(patchesDir, patchFile);
    const patchContent = JSON.parse(await readFile(patchPath, "utf-8"));

    const targetFilePath = join(targetDir, patchContent.file);
    let targetFileContent = await readFile(targetFilePath, "utf-8");

    for (const change of patchContent.changes) {
      if (change.action === "replace") {
        const searchRegex = new RegExp(change.search, "g");
        targetFileContent = targetFileContent.replace(
          searchRegex,
          change.replace,
        );
      }
    }

    await writeFile(targetFilePath, targetFileContent, "utf-8");
    patchedFiles.push(patchContent.file);
  }

  return patchedFiles;
}

async function showGitDiff(files: string[], repoDir: string) {
  // skip this if ran with --no-diff
  if (process.argv.includes("--no-diff")) {
    console.log("Skipping git diff...");
    return;
  }

  for (const file of files) {
    console.log(`Showing diff for ${file}...`);
    spawnSync(["git", "-C", repoDir, "diff", file], {
      stdout: "inherit",
      stderr: "inherit",
    });
  }
}

applyPatches().catch((err) => {
  console.error("Error applying patches:", err);
});

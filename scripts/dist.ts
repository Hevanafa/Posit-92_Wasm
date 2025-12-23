import { exists, mkdir, rm } from "node:fs/promises";
import { copyFile, cp } from "node:fs/promises";
import { styleText } from "node:util";

const wasmFile = "game.wasm";
const distDir = "dist";

const filesToCopy = ["game.js", wasmFile, "posit-92.js", "index.html"];

if (!await exists(wasmFile)) {
  console.log(styleText("red", `Missing ${wasmFile}!`));
  process.exit(1)
}

// TODO: Handle dist dir
// TODO: Copy files
// TODO: Copy assets folder

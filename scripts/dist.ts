import { mkdir, rm, copyFile, cp } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { styleText } from "node:util";

const wasmFile = "game.wasm";
const distDir = "dist";

if (!existsSync(wasmFile)) {
  console.log(styleText("red", `Missing ${wasmFile}!`));
  process.exit(1)
}

if (existsSync(distDir))
  await rm(distDir, { recursive: true });

await mkdir(distDir);

// Copy base files
const filesToCopy = ["game.js", wasmFile, "posit-92.js", "index.html"];

for (const file of filesToCopy)
  await copyFile(file, join(distDir, file));

// Assets folder
if (existsSync("assets"))
  await cp("assets", join(distDir, "assets"), { recursive: true });

console.log(styleText("green", `Files copied to ${distDir} successfully!`))

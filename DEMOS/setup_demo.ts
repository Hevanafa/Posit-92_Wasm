import { existsSync } from "node:fs";
import { readFile, writeFile, copyFile } from "node:fs/promises";
import { join } from "node:path";
import { styleText } from "node:util";

const demoName = Bun.argv[2];

if (demoName == "") {
  console.log(styleText("red", "Error: Demo name is required"));
  console.log(styleText("white", "Usage: bun setup_demo.ts sound"));
  process.exit(1)
}

if (demoName.includes("/") || demoName.includes("\\")) {
  console.log(styleText("red", "Error: Demo name should not contain path parameters"));
  console.log(styleText("white", "Use: bun setup_demo.ts sound"));
  console.log(styleText("white", "Not: bun setup_demo.ts .\\sound\\"));
  process.exit(1)
}

const mixinMap: Record<string, string[]> = {
  sound: ["sounds.js"],
  music: ["sounds.js"],
  bigint_demo: ["bigint.js"],
  webgl_demo: ["webgl.js"]
};

const scriptDir = import.meta.dir;
const demoPath = join(scriptDir, demoName);
const canonicalPosit = join(scriptDir, "../experimental/posit-92.js");
const mixinsDir = join(scriptDir, "../experimental/mixins");

// TODO: Check if demo exists
// TODO: Copy posit-92.js with header
// TODO: Handle mixins

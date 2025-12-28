/**
 * Migrated from the PowerShell version
 * This script must be placed at the root DEMOS folder
 */

const scriptsExcludes = [
  "square_screen",  // Has custom UNITS for unusual resolutions: PICO-8 Clone, GameBoy Jam & Nokia Jam
  "dos_display"  // Has custom UNITS
];

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

const demoScripts = [
  "build_run_demo.ts",
  "compile_demo.ts",
  "run_demo.ts",
  "server.ts"
];

const scriptDir = import.meta.dir;
const demoPath = join(scriptDir, demoName);
const canonicalPosit = join(scriptDir, "../experimental/posit-92.js");
const mixinsDir = join(scriptDir, "../experimental/mixins");

const scriptsDir = join(scriptDir, "../scripts");

// Check if demo exists
if (!existsSync(demoPath)) {
  console.log(styleText("magenta", `Couldn't find ${demoName} demo project!`));
  process.exit(1)
}

// Copy posit-92.js with header
const today = new Date().toISOString().split("T")[0];
const header = `// Copied from experimental/posit-92.js\n// Last synced: ${today}\n\n`;
const content = await readFile(canonicalPosit, "utf-8");
const destPath = join(demoPath, "posit-92.js");

await writeFile(destPath, header + content, "utf-8");
console.log(styleText("green", "Copied posit-92.js to " + demoName));

// Handle mixins
if (mixinMap[demoName]) {
  const required = mixinMap[demoName];

  for (const mixin of required) {
    const srcPath = join(mixinsDir, mixin);
    const destPath = join(demoPath, mixin);

    await copyFile(srcPath, destPath);
    console.log(styleText("green", `Copied ${mixin} to ${demoName}`))
  }
} else
  console.log(styleText("cyan", "No mixins needed for " + demoName));

// Handle copy build scripts
if (scriptsExcludes.includes(demoName))
  console.log(styleText("cyan", "Skipped copying build scripts to " + demoName))
else {
  for (const filename of demoScripts) {
    const srcPath = join(scriptsDir, filename);
    const destPath = join(demoPath, filename);

    await copyFile(srcPath, destPath)
  }

  console.log(styleText("green", "Copied build scripts to " + demoName))
}
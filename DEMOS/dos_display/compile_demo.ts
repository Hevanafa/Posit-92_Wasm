// Compile Script for Demo Projects
// Part of Posit-92 framework
// By Hevanafa, 12-12-2025

import { styleText } from "node:util";

const compilerPath = "E:\\fpc-wasm\\fpc\\bin\\x86_64-win64\\fpc.exe";
const primaryUnit = ".\\game.pas";
const outputFile = "game.wasm";

const proc = Bun.spawn([
  compilerPath,
  "-Pwasm32",
  "-Tembedded",
  "-FuUNITS",
  "-dWASM",
  `-o${outputFile}`,
  primaryUnit
], {
  stdout: "pipe",
  stderr: "pipe"
});

const stdout = await new Response(proc.stdout).text();
const stderr = await new Response(proc.stderr).text();
const exitCode = await proc.exited;

console.log(styleText("cyan", "(STDOUT)"));
console.log(stdout.trim() || styleText("gray", "(No data)"));

console.log(styleText("red", "(STDERR)"));
console.log(stderr.trim() || styleText("gray", "(No data)"));

if (exitCode != 0) {
  console.log(styleText("red", `Compilation failed with exit code ${exitCode}`));
  process.exit(exitCode)
}

export {}

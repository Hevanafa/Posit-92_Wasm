import { existsSync } from "node:fs";
import { styleText } from "node:util";

const wasmOptPath = "E:\\binaryen\\bin\\wasm-opt.exe";
const wasmFile = "game.wasm";
const outputFile = "game.wasm";  // replace the original by default

if (!existsSync(wasmFile)) {
  console.log(styleText("red", "Missing " + wasmFile + "!"));
  process.exit(1)
}

const args = [
  wasmOptPath,
  wasmFile,
  "-o",
  outputFile,
  "-Oz",
  "--strip-debug",
  "--enable-bulk-memory"
];

const proc = Bun.spawn(args);
const exitCode = await proc.exited;

if (exitCode != 0) {
  console.log(styleText("red", "Optimisation failed with exit code " + exitCode))
  process.exit(exitCode)
} else {
  console.log(styleText("green", "Finished optimising " + wasmFile))
}

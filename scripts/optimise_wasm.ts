import { existsSync } from "node:fs";
import { styleText } from "node:util";

const wasmOptPath = "E:\\binaryen\\bin\\wasm-opt.exe";
const wasmFile = "game.wasm";
const outputFile = "game.wasm";  // replace the original by default

if (!existsSync(wasmFile)) {
  console.log(styleText("red", "Missing " + wasmFile + "!"));
  process.exit(1)
}

const proc = Bun.spawn([
  wasmOptPath,
  "-Oz",
  "--strip-debug",
  "--enable-bulk-memory",
  wasmFile,
  `-o ${outputFile}`
])

console.log(styleText("green", "Finished optimising " + wasmFile))

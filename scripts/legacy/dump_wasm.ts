import { styleText } from "node:util";

const inputFile = "game.wasm";
const outfile = "analysis.txt";

console.log("Dumping WebAssembly data...");

const proc = Bun.spawn([
  "wasm-objdump",
  "-x",
  inputFile
], {
  stdout: Bun.file(outfile)
});

const exitcode = await proc.exited;

if (exitcode != 0)
  console.log(styleText("red", "Error when extracting WebAssembly data"))
else
  console.log(styleText("green", "Successfully dumped WebAssembly data to " + outfile))
export {}

const proc = Bun.spawn([
  "wasm-objdump",
  "-x",
  "game.wasm"
], {
  stdout: Bun.file("analysis.txt")
});

const exitcode = await proc.exited;
export {}

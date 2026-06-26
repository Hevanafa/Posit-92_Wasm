# Optimising Binary Size

This requires:

- The tools from [WebAssembly/binaryen](https://github.com/WebAssembly/binaryen) installed
- Assigned the bin folder of it to system PATH environment variable

## How it works

**tl;dr** Just use `optimise_wasm.pl` with `game.wasm` ready in the same folder

```powershell
perl .\optimise_wasm.pl
```

The optimisation flag `-Oz` (optimise for size) works well to reduce the size, similar to `-O3`

```powershell
wasm-opt -Oz --strip-debug game.wasm -o game.wasm
```

Here's the working command that is compatible with FPC's `wasm32-embedded` output

```powershell
E:\binaryen\bin\wasm-opt.exe -Oz --strip-debug --enable-bulk-memory game.wasm -o game.wasm
```

**Example size reduction:**

```text
Before: 574405 bytes (560 KB)
After : 391533 bytes (382 KB) (32% smaller)
```

Without the bulk memory compiler switch, it will throw this compile error:

```text
[wasm-validator error in function 118] unexpected false: memory.fill operations require bulk memory [--enable-bulk-memory-opt]
```

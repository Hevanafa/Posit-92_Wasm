#

![preview](preview.png)

This project is a port of [POSIT-92](https://github.com/Hevanafa/POSIT-92) which targets WebAssembly

## Requirements

1. **Free Pascal Compiler** which has been configured with `wasm32-embedded` as the target (read **Compiler Setup** section below to see how)
2. **VSCode** with the **[OmniPascal](https://marketplace.visualstudio.com/items?itemName=Wosi.omnipascal)** extension by Wosi enabled
3. **[Bun](https://bun.com/)** (at least v1.3.5) to handle both the build scripts (just like Perl) and also to start the HTTP server

I'm using Windows 10 Home (64-bit, version 22H2, build 19045.6575) to build this project

If you want to edit the build scripts with **Bun**, install the dependencies first with

```powershell
bun install
```

**Update 11-12-2025:** Changed the extension used

This is because the **Pascal** extension by Alessandro Fragnani is too difficult to get the "Go to definition" feature working, while **OmniPascal** can do it right out of the box

OmniPascal has a built-in code navigation, so it doesn't require GTags/CTags, GNU Global, or even Python installed

## Getting Started

1. Open VSCode terminal <kbd>Ctrl</kbd> + <kbd>~</kbd>
2. `cd boilerplate`
3. Run `bun .\setup.ts`
4. Choose which project version that you want:
   1. `default`
   2. `demo` is for demo projects, for use within this repo
5. Run `bun .\compile.ts`
   This will make sure that all the units can be compiled & run

When all the steps above is done, you can copy all the files of the `boilerplate` folder to your new project, except for `setup.ts`

## Build Tasks

I added build tasks in `tasks.json`, a few of them are:

- **Compile demo**
- **Start server** - This starts a new instance of the localhost server
- **Cleanup experimental** - This is essential for when there's internal compiler errors in demo projects
- **Rebuild glue code**

### Build Scripts

I have prepared a few scripts to ease the build process, which is located in `scripts` folder

- `build_run.ts` - Build & run
- `compile.ts` - Contains the command line to automatically delete the output file & compile the WebAssembly binary
- `run.ts` - Starts `server.ts`
- `server.ts` - Starts the local HTTP server

### Scripts for Demos

The demo projects use a special units collection: `experimental\units`, so the build scripts are slightly different

- `build_run_demo.ts` - Build & run
- `compile_demo.ts` - Compile only (similar to `compile.ts`)
- `run_demo.ts` - Starts `server.ts`
- `server.ts` - Starts the local HTTP server

### Distribution Scripts

Usually what you need are `optimise_wasm.ts` and `dist.ts`

The scripts are as follows:

- `build_dist.ts` - Build & distribute
- `dist.ts` - Gathers the key files required for distribution
- `optimise_wasm.ts` - Strips unused functions with `wasm-opt` (requires **Emscripten**)
- `dump_wasm.ts` - Dumps a WebAssembly binary file to `analysis.txt` (requires **Emscripten**)

## Compiler Setup

1. Download **fpcupdeluxe-x86_64-win64.exe** from [LongDirtyAnimAlf/fpcupdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases/)

   The version that I used at the time of writing was **v2.4.0g**

2. Install in `E:\fpc-wasm` or anywhere that's easy to reach
3. Under the **Basic** tab, choose the **trunk** version above the FPC button, install **Only FPC**

   ![Only FPC](./only_fpc_trunk.png)

4. Under the **Cross** tab, choose CPU: **wasm32**, OS: **embedded**, then click **Install compiler**

   ![wasm32-embedded](./wasm32_embedded.png)

It took me a few retries until the compiler finally completed compiling

Just in case you want to use a different installation folder, you can change `$compilerPath` in these scripts:

- `compile.ts` - Main compile script
- Optional: `compile_demo.ts` - Change this if you want to play around with the demos

## Optimising Binary Size

This requires:

- The tools from [WebAssembly/binaryen](https://github.com/WebAssembly/binaryen) installed
- Assigned the bin folder of it to system PATH environment variable

### How it works

tl;dr Just use `optimise_wasm.ts` with `game.wasm` ready in the same folder

The optimisation flag `-Oz` (optimise for size) works well to reduce the size, similar to `-O3`

```powershell
wasm-opt -Oz --strip-debug game.wasm -o game.wasm
```

Here's the working command that is suitable with FPC's `wasm32-embedded` output

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

## What To Do

When there is a compiler error especially in the demo projects, something like this:

```text
SHAPES.PAS(110,3) Fatal: Internal error 2010120506
```

Simply call the cleanup script in experimental, then rebuild

## Credits

Default font: [Nokia Cellphone FC](https://www.dafont.com/nokia-cellphone.font)

BMFont format: [AngelCode BMFont](https://www.angelcode.com/products/bmfont/)

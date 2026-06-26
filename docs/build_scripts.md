# Build Tasks

I added build tasks in `tasks.json`, a few of them are:

- **Compile demo**
- **Start server** - This starts a new instance of the localhost server
- **Cleanup experimental** - This is essential for when there's internal compiler errors in demo projects
- **Rebuild glue code**

# Build Scripts

I have prepared a few scripts to ease the build process, which is located in `scripts` folder

- `build_run.ts` - Build & run
- `compile.ts` - Contains the command line to automatically delete the output file & compile the WebAssembly binary
- `run.ts` - Starts `server.ts`
- `server.ts` - Starts the local HTTP server

## Scripts for Demos

The demo projects use a special units collection: `experimental\units`, so the build scripts are slightly different

- `build_run_demo.ts` - Build & run
- `compile_demo.ts` - Compile only (similar to `compile.ts`)
- `run_demo.ts` - Starts `server.ts`
- `server.ts` - Starts the local HTTP server

## Distribution Scripts

Usually what you need are `optimise_wasm.ts` and `dist.ts`

The scripts are as follows:

- `build_dist.ts` - Build & distribute
- `dist.ts` - Gathers the key files required for distribution
- `optimise_wasm.ts` - Strips unused functions with `wasm-opt` (requires **Emscripten**)
- `dump_wasm.ts` - Dumps a WebAssembly binary file to `analysis.txt` (requires **Emscripten**)

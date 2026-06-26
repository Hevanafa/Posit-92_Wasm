# Build Scripts

I have prepared a few scripts to ease the build process, which is located in `scripts` folder

- `clean.pl` - Cleans up auto-generated files including **lib** and **backup**
- `make.pl` - Contains the command line to automatically delete the output file & compile the WebAssembly binary
- `server.ts` - Starts the local HTTP server

The Perl scripts are usually unnecessary when you're already building with Lazarus

## Scripts for Demos

The demo projects use a special units collection: `experimental\units`, so the build scripts are slightly different

- `make_demo.ts` - Compile only (similar to `make.ts`)
- `server.ts` - Starts the local HTTP server

## Distribution Scripts

Usually what you need are `optimise_wasm.ts` and `dist.ts`

The scripts are as follows:

- `dist.pl` - Gathers the key files required for distribution
- `optimise_wasm.pl` - Strips unused functions with `wasm-opt` (requires **Emscripten**)
- (legacy) `dump_wasm.ts` - Dumps a WebAssembly binary file to `analysis.txt` (requires **Emscripten**)

## Build Tasks

I added build tasks in `tasks.json`, a few of them are:

- **Compile demo**
- **Start server** - This starts a new instance of the localhost server
- **Cleanup experimental** - This is essential for when there's internal compiler errors in demo projects
- **Rebuild glue code**

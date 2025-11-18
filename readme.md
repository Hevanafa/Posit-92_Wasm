# POSIT-92 Wasm

This project is a port of [POSIT-92](https://github.com/Hevanafa/POSIT-92) which targets WebAssembly

## Requirements

1. **Free Pascal Compiler** which has been configured with `wasm32-embedded` as the target (read **Installation** section to see how)
2. Any version of **Node.js** to start the `http-server`

## Building

I have prepared a few scripts to ease the build process

- `build_run.ps1` - Build & run
- `run.ps1` - Run without building
- `compile.ps1` - Contains the command line to automatically delete the output file & compile the WebAssembly binary
- `start_server.ps1` - Starts the `http-server`
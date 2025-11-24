#

![preview](preview.png)

This project is a port of [POSIT-92](https://github.com/Hevanafa/POSIT-92) which targets WebAssembly

## Requirements

1. **Free Pascal Compiler** which has been configured with `wasm32-embedded` as the target (read **Installation** section to see how)
2. **VSCode** with **Pascal** extension by Alessandro Fragnani enabled
3. Any version of **Node.js** to start the `http-server`
4. **PowerShell 7** installed ([WinGet](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.5#winget))

I'm using Windows 10 Home (64-bit, version 22H2, build 19045.6575) to build this project

## Building

I have prepared a few scripts to ease the build process

- `build_run.ps1` - Build & run
- `run.ps1` - Run without building
- `compile.ps1` - Contains the command line to automatically delete the output file & compile the WebAssembly binary
- `start_server.ps1` - Starts the `http-server`

## Installation

1. Download **fpcupdeluxe-x86_64-win64.exe** from [LongDirtyAnimAlf/fpcupdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases/)

   The version that I used at the time of writing was **v2.4.0g**

2. Install in `E:\lazarus-wasm` or anywhere that's easy to reach
3. Under the **Basic** tab, install both FPC and Lazarus, both the **trunk** version
4. Under the **Cross** tab, choose CPU: **wasm32**, OS: **embedded**, then click **Install compiler**

   It took me a few retries until the compiler finally completed compiling

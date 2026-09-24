# Manual boilerplate copying

This document is more of a guideline on how to get started with the statically linked Posit-92 engine

## Preparation

- Create a new folder for your project
  - For example: `Posit-92_hello_world`
- Enter `experimental` then run `tsc` once
  - This step is to transpile the engine's glue code
- Copy the content of `hello_demoscene` to your project directory
- Copy these files to your project's root:
  - `experimental\engine\posit-92.js` - this is the engine's main glue code
  - `experimental\mixins\` then pick your mixin files, typically `p92-bmfont.mixin.js` and `p92-sound.mixin.js`

## Building

- Open `game.lpi` with Lazarus
- Build the `game.wasm`

Double check your compiler settings in **Tools menu > Options**

The compiler executable and FPC source directory must match the target `wasm32-embedded`

For example:

Compiler executable:

```text
E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe
```

FPC source directory:

```text
E:\fpc-wasm\fpcsrc
```

As far as I know, there's no build & run option by default, since the project type is a `library` anyway

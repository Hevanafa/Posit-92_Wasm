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

1. Open VSCode terminal `Ctrl + ~`
2. `cd boilerplate`
3. Run `bun .\setup.ts`
4. Choose which project version that you want:
   1. `default`
   2. `demo` is for demo projects, for use within this repo
5. Run `bun .\compile.ts`
   This will make sure that all the units can be compiled & run

When all the steps above is done, you can copy all the files of the `boilerplate` folder to your new project, except for `setup.ts`

### Experimental Boilerplate

First, choose either `hello_quick`, `hello_intro` or `hello_minimal` from the `DEMOS` folder

- `hello_quick` is the recommended project because of the complete asset loader and Lazarus project files included
- `hello_intro` is like `hello_quick` but with the intro sequence included
- `hello_minimal` is the bare minimum just to get a plain black surface & text output on the console

This will be the base directory for your future project

Second, copy both `posit-92.ts` and `tsconfig.json` from the `experimental` folder

Third, copy `experimental\units` excluding the `backup` and `deprecated` folders, and then name it as `shared`

Fourth, copy the `server.ts` and `dist.ts` build scripts from `scripts`

Here's the project structure:

```text
hello_quick\
- shared\
- (all files from hello_quick)
- game.lpi
- game.lpr
- posit-92.ts
- tsconfig.json
- server.ts
- dist.ts
```

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

## Credits

Default font: [Nokia Cellphone FC](https://www.dafont.com/nokia-cellphone.font)

BMFont format: [AngelCode BMFont](https://www.angelcode.com/products/bmfont/)

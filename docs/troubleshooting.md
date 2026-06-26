# Troubleshooting

## Fatal: Internal error

When there is a compiler error especially in the demo projects, something like this:

```text
SHAPES.PAS(110,3) Fatal: Internal error 2010120506
```

Simply call the clean script and rebuild, or in Lazarus: **Run > Clean up and build**

## Lazarus - Invalid symbol type: 6
25-06-2026

An example case is this error message that appears when trying to build with Lazarus

```
wasm-ld: error: (project_path)\utf8_strings\lib\wasm32-embedded\LOGGER.o: invalid symbol type: 6
```

I remember this error message had occurred in the early days of the development of Posit-92 WASM

### How to solve

Make sure that in **Tools > Options**, both the compiler executable and FPC source directory have been configured as follows:

Compiler executable:
```
E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe
```

FPC source directory:
```
E:\fpc-wasm\fpcsrc
```

The paths depend on where you installed FPC's WebAssembly compiler targeting `wasm32-embedded`

Now the fix:

1. In Lazarus IDE, open **Project > Project Options**
2. Scroll down to **Compiler Options > Debugging**
3. Turn off both **Run uses the debugger** and **Generate info for the debugger**
4. **Optional:** Turn off "Display line numbers in run-time error backtraces (-gl)"
5. Press OK

@echo off

echo Compiling Pascal...
E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded .\main.pas
del main.wasm 2>nul
ren main main.wasm

echo Compiling TypeScript...
tsc index.ts

echo Build complete!

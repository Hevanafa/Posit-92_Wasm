@ECHO OFF
E:\binaryen\bin\wasm-opt.exe game.wasm -o game.wasm -Oz --strip-debug --enable-bulk-memory

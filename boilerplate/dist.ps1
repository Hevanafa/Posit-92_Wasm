$wasmFile = "wasm"

if (test-path -path "$wasmFile.wasm" -pathType leaf) {}
else {
  write-host "Missing $wasmFile.wasm!" -foregroundColor red
  exit 1
}


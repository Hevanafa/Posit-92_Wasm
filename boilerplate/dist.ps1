$wasmFile = "game.wasm"
$distDir = "dist"

if (test-path -path $wasmFile -pathType leaf) {}
else {
  write-host "Missing $wasmFile!" -foregroundColor red
  exit 1
}

if (test-path -path $distDir -pathType container) {}
else {
  mkdir $distDir
}

copy-item "game.js" "$distDir\"
copy-item $wasmFile "$distDir\"
copy-item "posit-92.js" "$distDir\"
copy-item "index.html" "$distDir\"

# TODO: Copy assets folder recursively to $distDir

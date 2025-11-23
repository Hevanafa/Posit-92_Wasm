$wasmFile = "game.wasm"
$distDir = "dist"

if (test-path -path $wasmFile -pathType leaf) {}
else {
  write-host "Missing $wasmFile!" -foregroundColor red
  exit 1
}

if (test-path -path $distDir -pathType container) {
  remove-item "$distDir\*" -recurse -force
} else {
  mkdir $distDir
}

copy-item "game.js" "$distDir\"
copy-item $wasmFile "$distDir\"
copy-item "posit-92.js" "$distDir\"
copy-item "index.html" "$distDir\"

# Copy assets folder recursively to $distDir
if (test-path -path "assets" -pathType container) {
  copy-item "assets" "$distDir\" -recurse -force
}

write-host "Files copied to $distDir successfully!" -foregroundColor green

$wasmOpt = "E:\emsdk\upstream\bin\wasm-opt.exe"
$infile = $args[0]
$outfile = $infile -replace ".wasm", "_stripped.wasm"

& $wasmOpt $infile -O3 --enable-bulk-memory --strip-debug --strip-producers -o $outfile

write-host "Stripped: $outfile" -foregroundColor green

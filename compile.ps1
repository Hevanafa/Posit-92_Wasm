$compilerPath = "E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe"
$primaryUnit = ".\game.pas"
$outputFile = "game"

# Compile targetting wasm32-embedded
E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded -FuUNITS $primaryUnit
# This doesn't output to STDOUT
# start-process -filePath $compilerPath -argumentList ("-Pwasm32", "-Tembedded", "-FuUNITS", $primaryUnit)

if ($LastExitCode -ne 0) {
  write-host "Compilation failed with exit code $LastExitCode" -foregroundColor red
  exit $LastExitCode
}

if (test-path -path "$outputFile.wasm" -pathType leaf) {
  del "$outputFile.wasm"
}

if (test-path -path "$outputFile" -pathType leaf) {
  ren "$outputFile" "game.wasm"
}

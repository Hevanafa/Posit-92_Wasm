$compilerPath = "E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe"
$primaryUnit = ".\game.pas"
$outputFile = "game"

# Compile targetting wasm32-embedded
# E:\lazarus-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded -FuUNITS $primaryUnit

$pinfo = new-object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $compilerPath
$pinfo.Arguments = "-Pwasm32", "-Tembedded", "-FuUNITS", $primaryUnit
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false

$p = new-object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

write-host "(STDOUT)"
write-host $stdout
write-host "(STDERR)"
write-host $stderr

if ($p.ExitCode -ne 0) {
  write-host "Compilation failed with exit code $($p.ExitCode)" -foregroundColor red
  exit $p.ExitCode
}

if (test-path -path "$outputFile.wasm" -pathType leaf) {
  del "$outputFile.wasm"
}

if (test-path -path "$outputFile" -pathType leaf) {
  ren "$outputFile" "game.wasm"
}

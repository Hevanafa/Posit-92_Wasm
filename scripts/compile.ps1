# Compile Script
# Part of Posit-92 framework
# By Hevanafa, 17-11-2025

$compilerPath = "E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe"
$primaryUnit = ".\game.pas"
$outputFile = "game.wasm"

# Compile targetting wasm32-embedded
# E:\fpc-wasm\fpc\bin\x86_64-win64\fpc.exe -Pwasm32 -Tembedded -FuUNITS -ogame.wasm .\game.pas

$pinfo = new-object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = $compilerPath
$pinfo.Arguments = "-Pwasm32", "-Tembedded", "-FuUNITS", "-o$outputFile", $primaryUnit
$pinfo.WorkingDirectory = $PSScriptRoot
$pinfo.RedirectStandardError = $true
$pinfo.RedirectStandardOutput = $true
$pinfo.UseShellExecute = $false

$p = new-object System.Diagnostics.Process
$p.StartInfo = $pinfo
$p.Start() | Out-Null
$p.WaitForExit()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

write-host "(STDOUT)" -foregroundColor cyan
if ($stdout.Trim() -eq "") {
  write-host "(No data)" -foregroundColor gray
} else {
  write-host $stdout
}
write-host "(STDERR)" -foregroundColor red
if ($stderr.Trim() -eq "") {
  write-host "(No data)" -foregroundColor gray
} else {
  write-host $stderr
}

if ($p.ExitCode -ne 0) {
  write-host "Compilation failed with exit code $($p.ExitCode)" -foregroundColor red
  exit $p.ExitCode
}

# if (test-path -path "$outputFile.wasm" -pathType leaf) {
#   remove-item "$outputFile.wasm"
# }

# if (test-path -path "$outputFile" -pathType leaf) {
#   rename-item "$outputFile" "$outputFile.wasm"
# }

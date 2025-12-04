param(
  [parameter(mandatory=$true)]
  [string]$demoName
)

if ($demoName -match '[\\\/]') {
  write-host "Error: Demo name should not contain path parameters" -ForegroundColor red
  write-host "Use: .\setup-demo.ps1 sound" -ForegroundColor white
  write-host "Not: .\setup_demo.ps1 .\sound\" -ForegroundColor white
  exit 1
}

$mixinMap = @{
  "loading_demo" = @("loading.js")
  "sound" = @("sounds.js")
  "music" = @("sounds.js")
  "bigint_demo" = @("bigint.js")
  "webgl_demo" = @("webgl.js")
}

$demoPath = join-path $PSScriptRoot $demoName
$canonicalPosit = join-path $PSScriptRoot "..\experimental\posit-92.js"
$mixinsDir = join-path $PSScriptRoot "..\experimental\mixins"

$today = get-date -format "yyyy-MM-dd"

# Check if demo exists
if (-not (test-path $demoPath)) {
  write-host "Couldn't find $demoName demo project" -foregroundColor magenta
  exit 1
}

$header = "// Copied from experimental/posit-92.js`n// Last synced: $today`n`n"
$content = get-content $canonicalPosit -raw
$content = $header + $content

$destPath = join-path $demoPath "posit-92.js"
set-content -path $destPath -value $content -noNewLine

write-host "Copied posit-92.js to $demoName" -foregroundColor green

# Handle copy mixins
if ($mixinMap.ContainsKey($demoName)) {
  $required = $mixinMap[$demoName]

  foreach ($mixin in $required) {
    $srcPath = join-path $mixinsDir $mixin
    $destPath = join-path $demoPath $mixin

    copy-item $srcPath $destPath
    write-host "Copied $mixin to $demoName" -foregroundColor green
  }
} else {
  write-host "No mixins needed for $demoName" -foregroundColor cyan
}

# TODO: Success message

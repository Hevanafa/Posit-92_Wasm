param(
  [parameter(mandatory=$true)]
  [string]$demoName
)

$mixinMap = @{
  "sound" = @("sounds.js")
  "music" = @("sounds.js")
  "bigint" = @("bigint.js")
  "webgl" = @("webgl.js")
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

# TODO: COpy mixins if needed
# TODO: Success message

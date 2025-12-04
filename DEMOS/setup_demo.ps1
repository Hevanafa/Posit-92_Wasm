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

# TODO: Check if demo exists
# TODO: Copy posit-92.js with comment
# TODO: COpy mixins if needed
# TODO: Success message

$demoFolders = get-childItem -path $PSScriptRoot -directory
$skip = @()  # "loading"

foreach ($demo in $demoFolders) {
  $demoName = $demo.Name

  if ($skip -contains $demoName) {
    write-host "Skipping $demoName (special case)" -foregroundColor cyan
    continue
  }

  write-host "Setting up: $demoName" -foregroundColor yellow
  
  # & <-- Call operator
  # Basically runs a script with the argument $demoName
  & (join-path $PSScriptRoot "setup_demo.ps1") $demoName
}
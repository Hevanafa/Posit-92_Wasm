$demoFolders = get-childItem -path $PSScriptRoot -directory
$skip = @("loading")

foreach ($demo in $demoFolders) {
  $demoName = $demo.Name

  if ($skip -contains $demoName) {
    write-host "Skipping $demoName (special case)" -foregroundColor cyan
    continue
  }

  write-host "Setting up: $demoName" -foregroundColor yellow
  # TODO: Call the script in each demo
}
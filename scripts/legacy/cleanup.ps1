# Recursively removes all .o and .ppu files

$files = Get-ChildItem -include *.o, *.ppu -recurse -file

if ($files.count -eq 0) {
  write-host "No .o or .ppu files found" -foregroundColor white
} else {
  write-host "Found $($files.count) file(s) to delete" -foregroundColor yellow

  $files | foreach-object { write-host "  $($_.FullName)" }

  # Assuming that no files are locked after compilation
  $files | remove-item
  write-host "Deleted $($files.count) file(s)" -foregroundColor cyan
}

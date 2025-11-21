# Setup Boilerplate
# By Hevanafa, 21-11-2025
# Part of Posit-92 framework

# This script should be executed before copying as a new demo

$source = ".."

copy-item "$source\UNITS\*.pas" ".\"
copy-item "$source\*.ps1" ".\"
copy-item "$source\posit-92.js" ".\"

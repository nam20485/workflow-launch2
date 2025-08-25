# get parent directory name
$repoFolder = (Split-Path -Path $PSScriptRoot -Parent)
$repoFolderName = Split-Path -Path $repoFolder -Leaf

# rename a file

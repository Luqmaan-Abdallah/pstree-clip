$RootPath = Resolve-Path "."
$report = [System.Text.StringBuilder]::new()

$allFiles = Get-ChildItem -Path $RootPath -Recurse

foreach ($item in $allFiles) {
    $RelativePath = $item.FullName.Replace($RootPath.Path, "")
    $Depth = ($RelativePath -split '\\').Count - 1
    $Indent = "  " * $Depth

    $symbol = if ($item.PSIsContainer) { "+ " } else { "- " }

    [void]$report.AppendLine("$Indent$symbol$($item.Name)")
}

$report.ToString() | Set-Clipboard
Write-Host "Success! The recursive tree is in your clipboard." -ForegroundColor Green
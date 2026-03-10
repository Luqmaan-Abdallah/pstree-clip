$RootPath = Resolve-Path "."
$IgnoreFile = Join-Path $RootPath.Path ".treeignore"
$IgnoreList = @(".treeignore")

if (Test-Path $IgnoreFile) {
    $IgnoreList += Get-Content $IgnoreFile | Where-Object { $_ -match '\S' }
}

$report = [System.Text.StringBuilder]::new()

$allFiles = Get-ChildItem -Path $RootPath -Recurse | Where-Object {
    $shouldIgnore = $false
    foreach ($pattern in $IgnoreList) {
        if ($_.FullName -match [regex]::Escape($pattern)) { 
            $shouldIgnore = $true
            break 
        }
    }
    !$shouldIgnore
}

foreach ($item in $allFiles) {
    $RelativePath = $item.FullName.Replace($RootPath.Path, "").TrimStart('\')
    $Depth = if ($RelativePath -eq "") { 0 } else { ($RelativePath -split '\\').Count - 1 }
    
    $Indent = "  " * $Depth
    $symbol = if ($item.PSIsContainer) { "+ " } else { "- " }

    [void]$report.AppendLine("$Indent$symbol$($item.Name)")
}

$report.ToString() | Set-Clipboard
Write-Host "Success! The tree is in your clipboard." -ForegroundColor Green
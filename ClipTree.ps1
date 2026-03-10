function Clip-Tree {
    $RootPath = (Resolve-Path ".").Path
    $IgnoreFile = Join-Path $RootPath ".treeignore"
    $IgnoreList = @(".treeignore")

    if (Test-Path $IgnoreFile) {
        $IgnoreList += Get-Content $IgnoreFile | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
    }

    $report = [System.Text.StringBuilder]::new()

    $allFiles = Get-ChildItem -Path $RootPath -Recurse | Where-Object {
        $itemPath = $_.FullName
        $shouldIgnore = $false
        foreach ($pattern in $IgnoreList) {
            if ($itemPath -like "*$pattern*") { 
                $shouldIgnore = $true
                break 
            }
        }
        !$shouldIgnore
    } | Sort-Object FullName

    foreach ($item in $allFiles) {
        $RelativePath = $item.FullName.Substring($RootPath.Length).TrimStart('\')
        if ([string]::IsNullOrWhiteSpace($RelativePath)) { continue }
        
        $PathParts = $RelativePath -split '\\'
        $Depth = $PathParts.Count - 1
        
        $Indent = "  " * $Depth
        $symbol = if ($item.PSIsContainer) { "+ " } else { "- " }
        [void]$report.AppendLine("$Indent$symbol$($item.Name)")
    }

    $report.ToString() | Set-Clipboard
    Write-Host "Success! Tree structure copied to clipboard." -ForegroundColor Green
}

Set-Alias -Name cliptree -Value Clip-Tree
Set-Alias -Name ct -Value Clip-Tree
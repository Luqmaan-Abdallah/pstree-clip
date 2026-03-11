function Get-Tree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('Classic', 'Modern', 'Visual')]
        [string]$Style = $(if ($Global:GetTreeDefaultStyle) { $Global:GetTreeDefaultStyle } else { 'Classic' }),

        [switch]$Quiet = $(if ($Global:GetTreeDefaultQuiet) { $Global:GetTreeDefaultQuiet } else { $false })
    )

    $RootPath = (Resolve-Path ".").Path
    $IgnoreFile = Join-Path $RootPath ".treeignore"
    $IgnoreList = @(".treeignore", ".git")

    if (Test-Path $IgnoreFile) {
        $IgnoreList += Get-Content $IgnoreFile | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
    }

    $report = [System.Text.StringBuilder]::new()

    $allFiles = Get-ChildItem -Path $RootPath -Recurse -Force | Where-Object {
        $itemPath = $_.FullName
        $shouldIgnore = $false
        foreach ($pattern in $IgnoreList) {
            if ($itemPath -split '\\' -contains $pattern) { 
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

        $symbol = ""
        switch ($Style) {
            'Modern' {
                $symbol = if ($item.PSIsContainer) { "$([char]0x251C)$([char]0x2500) " } else { "$([char]0x2514)$([char]0x2500) " }
            }
            'Visual' {
                $symbol = if ($item.PSIsContainer) { "$([char]0xD83D)$([char]0xDCC1) " } else { "$([char]0xD83D)$([char]0xDCC4) " }
            }
            Default {
                $symbol = if ($item.PSIsContainer) { "+ " } else { "- " }
            }
        }

        [void]$report.AppendLine("$Indent$symbol$($item.Name)")
    }

    $finalTree = $report.ToString()
    $E = [char]27

    try {
        $finalTree | Set-Clipboard -ErrorAction Stop
        
        if (-not $Quiet) {
            Write-Output "$E[32m$E[3mCopied to clipboard$E[0m"
        }
    }
    catch {
        Write-Output "$E[33m$E[3mClipboard unavailable. Displaying output instead:$E[0m"
        Write-Output $finalTree
    }
}

Set-Alias -Name ct -Value Get-Tree -Force
Set-Alias -Name Clip-Tree -Value Get-Tree -Force

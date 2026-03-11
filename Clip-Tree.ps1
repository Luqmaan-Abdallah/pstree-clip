$Script:GetTreeDefaultStyle = 'Classic'
$Script:GetTreeDefaultQuiet = $false

function Set-TreeConfig {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias('s')]
        [string]$Style,
        
        [Parameter(Position = 1)]
        [Alias('q')]
        [bool]$Quiet
    )
    if ($PSBoundParameters.ContainsKey('Style')) { $Script:GetTreeDefaultStyle = $Style }
    if ($PSBoundParameters.ContainsKey('Quiet')) { $Script:GetTreeDefaultQuiet = $Quiet }
}

function Get-Tree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position = 0)]
        [Alias('s')]
        [string]$Style = $Script:GetTreeDefaultStyle,

        [Parameter(Mandatory=$false)]
        [Alias('q')]
        [switch]$Quiet = $Script:GetTreeDefaultQuiet,

        [Parameter(Mandatory=$false, Position = 1)]
        [Alias('d')]
        [int]$Depth = 0
    )

    $RootPath = (Resolve-Path ".").Path
    $IgnoreFile = Join-Path $RootPath ".treeignore"
    $IgnoreList = @(".treeignore", ".git")

    if (Test-Path $IgnoreFile) {
        $IgnoreList += Get-Content $IgnoreFile | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
    }

    $report = [System.Text.StringBuilder]::new()

    $gciParams = @{
        Path    = $RootPath
        Recurse = $true
        Force   = $true
    }
    if ($PSBoundParameters.ContainsKey('Depth') -and $Depth -gt 0) { $gciParams['Depth'] = $Depth }

    $allFiles = Get-ChildItem @gciParams | Where-Object {
        $itemPath = $_.FullName
        $pathParts = $itemPath -split '\\'
        $shouldIgnore = $false
        foreach ($pattern in $IgnoreList) {
            if ($pathParts -contains $pattern) { 
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
        $itemDepth = $PathParts.Count - 1
        $Indent = "  " * $itemDepth

        $symbol = ""
        switch -Wildcard ($Style) {
            "m*" {
                $symbol = if ($item.PSIsContainer) { "$([char]0x251C)$([char]0x2500) " } else { "$([char]0x2514)$([char]0x2500) " }
            }
            "v*" {
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
        if ([string]::IsNullOrWhiteSpace($finalTree)) { throw "No files found." }
        $finalTree | Set-Clipboard -ErrorAction Stop
        
        if (-not $Quiet) {
            $displayStyle = switch -Wildcard ($Style) { "m*" {"Modern"}; "v*" {"Visual"}; Default {"Classic"} }
            Write-Output "$E[32m$E[3mCopied to clipboard$E[0m"
        }
    }
    catch {
        Write-Output "$E[33m$E[3mClipboard unavailable. Outputting to terminal:$E[0m"
        Write-Output $finalTree
    }
}

Set-Alias -Name ct -Value Get-Tree -Force
Set-Alias -Name Clip-Tree -Value Get-Tree -Force
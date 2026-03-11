# --- Module Internal State (Defaults) ---
$Script:GetTreeDefaultStyle = 'Classic'
$Script:GetTreeDefaultQuiet = $false

function Update-TreeConfig {
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    param(
        [Parameter(Position = 0)]
        [Alias('s')]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            ('Classic', 'Modern', 'Visual') | Where-Object { $_ -like "$WordToComplete*" }
        })]
        [string]$Style,

        [Parameter(Position = 1)]
        [Alias('q')]
        [bool]$Quiet
    )

    if ($PSCmdlet.ShouldProcess("Module Configuration", "Update Defaults")) {
        if ($PSBoundParameters.ContainsKey('Style')) { $Script:GetTreeDefaultStyle = $Style }
        if ($PSBoundParameters.ContainsKey('Quiet')) { $Script:GetTreeDefaultQuiet = $Quiet }
    }
}

function Get-Tree {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param(
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Path = ".",

        [Parameter(Position = 1, Mandatory = $false)]
        [Alias('s')]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            ('Classic', 'Modern', 'Visual') | Where-Object { $_ -like "$WordToComplete*" }
        })]
        [string]$Style = $Script:GetTreeDefaultStyle,

        [Parameter(Mandatory = $false)]
        [Alias('q')]
        [switch]$Quiet = $Script:GetTreeDefaultQuiet,

        [Parameter(Mandatory = $false, Position = 2)]
        [Alias('d')]
        [int]$Depth = 0
    )

    process {
        $StyleKeywords = @('classic', 'modern', 'visual', 'c', 'm', 'v')
        if (-not (Test-Path -Path $Path) -and ($StyleKeywords -contains $Path.ToLower())) {
            $Style = $Path
            $Path = "."
        }

        try {
            $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
            $RootPath = $ResolvedPath.Path
        }
        catch {
            Write-Error "Could not find path: $Path"
            return
        }

        $IgnoreFile = Join-Path $RootPath ".treeignore"
        $IgnoreList = @(".treeignore", ".git")

        if (Test-Path $IgnoreFile) {
            $IgnoreList += Get-Content $IgnoreFile |
                Where-Object { $_ -match '\S' } |
                ForEach-Object { $_.Trim().TrimEnd('\').TrimEnd('/') }
        }

        $report = [System.Text.StringBuilder]::new()

        $gciParams = @{
            Path    = $RootPath
            Recurse = $true
            Force   = $true
        }
        if ($PSBoundParameters.ContainsKey('Depth') -and $Depth -gt 0) { $gciParams['Depth'] = $Depth }

        $allFiles = Get-ChildItem @gciParams | Where-Object {
            $item = $_
            $shouldIgnore = $false
            $RelativePath = $item.FullName.Substring($RootPath.Length).TrimStart('\')
            $pathParts = $RelativePath -split '\\'

            foreach ($pattern in $IgnoreList) {
                if ($item.Name -like $pattern -or ($pathParts -contains $pattern)) {
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

        if ([string]::IsNullOrWhiteSpace($finalTree)) {
            if (-not $Quiet) {
                Write-Host "$E[33mNo files found in: $RootPath$E[0m"
            }
            return
        }

        $isRedirected = $MyInvocation.ExpectingInput -or $PSCmdlet.MyInvocation.PipelineLength -gt 1
        if ($isRedirected -or -not $Quiet) {
            Write-Output $finalTree
        }

        try {
            $finalTree | Set-Clipboard -ErrorAction Stop
            if (-not $Quiet) {
                Write-Host "$E[32m$E[3mCopied to clipboard$E[0m"
            }
        }
        catch {
            if (-not $Quiet) {
                Write-Host "$E[33m$E[3mClipboard unavailable.$E[0m"
            }
        }
    }
}

Set-Alias -Name gt -Value Get-Tree -Force
Set-Alias -Name ct -Value Get-Tree -Force
Set-Alias -Name Clip-Tree -Value Get-Tree -Force
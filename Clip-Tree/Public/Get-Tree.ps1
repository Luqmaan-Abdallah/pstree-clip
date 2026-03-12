# (c) 2026 Luqmaan Abdallah | MIT License

function Get-Tree {
<#
.SYNOPSIS
    Generates a directory tree structure and copies it to the clipboard.

.DESCRIPTION
    Get-Tree scans a directory and creates a visual representation (Classic, Modern, or Visual).
    The output is automatically copied to the clipboard for easy pasting into documentation or chat.

.PARAMETER Path
    The folder path to scan. Defaults to the current directory (.).
    If a style name (e.g., 'modern') is passed here and the path doesn't exist, it switches the style instead.

.PARAMETER Style
    The visual style of the tree:
    - Classic: Uses + and - (Default)
    - Modern: Uses box-drawing characters (├─, └─)
    - Visual: Uses Folder and File emojis

.PARAMETER Quiet
    If specified, suppresses all console output except for the tree itself if piped.

.PARAMETER Depth
    Limits how many levels deep the scan goes. 0 is infinite.

.EXAMPLE
    Get-Tree
    Generates a classic style tree of the current directory and copies it to the clipboard.

.EXAMPLE
    Get-Tree -Path .\src -Style Modern
    Generates a tree of the 'src' folder using box-drawing characters (├─, └─).

.EXAMPLE
    ct -Style Visual
    Uses the short alias 'ct' to generate a tree using Folder and File emojis.

.EXAMPLE
    Get-Tree -Depth 2
    Scans the current directory but limits the output to only 2 levels of nesting.

.EXAMPLE
    Get-Tree -DirectoryOnly
    Generates a tree consisting only of folders, ignoring all files.

.EXAMPLE
    Get-Tree "Modern"
    Uses the shorthand logic to switch the style to 'Modern' for the current directory scan.

.EXAMPLE
    Get-Tree -Quiet
    Suppresses the "Copied to clipboard" and "Items found" status messages, outputting only the raw tree.

.EXAMPLE
    "C:\Temp", "C:\Logs" | Get-Tree
    Processes multiple paths from the pipeline, generating and copying trees for each.

.EXAMPLE
    Get-Tree > tree.txt
    Generates the directory tree, copies the result to the system clipboard, and redirects the console output to create 'tree.txt'.

.NOTES
    Requires Set-Clipboard. If the clipboard is unavailable, the tree is still output to the console.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param(
        # The target directory.
        # Position 0: Allows 'Get-Tree C:\Windows' without typing -Path.
        # ValueFromPipeline: Allows '"C:\Path1", "C:\Path2" | Get-Tree'.
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Path = ".",

        # The visual formatting style.
        # Position 1: Allows 'Get-Tree . Modern'.
        # Alias 's': Allows 'Get-Tree -s Modern'.
        # ArgumentCompleter: Provides Tab-Completion for Classic, Modern, and Visual in the terminal.
        # Default: Pulls from the $Script: variable set by Update-TreeConfig.
        [Parameter(Position = 1, Mandatory = $false)]
        [Alias('s')]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            $null = $CommandName, $ParameterName, $CommandAst, $FakeBoundParameters

            ('Classic', 'Modern', 'Visual') | Where-Object { $_ -like "$WordToComplete*" }
        })]
        [string]$Style = $(if ($Script:GetTreeDefaultStyle) { $Script:GetTreeDefaultStyle } else { "Modern" }),

        # Suppresses status messages (e.g., "Copied to clipboard").
        # [switch]: A boolean toggle. Used as '-Quiet' (True) or omitted (False).
        # Default: Pulls from the session-wide default set by Update-TreeConfig.
        [Parameter(Mandatory = $false)]
        [Alias('q')]
        [switch]$Quiet = $Script:GetTreeDefaultQuiet,

        # Controls recursion depth.
        # Position 2: Allows 'Get-Tree . Modern 2'.
        # [int]: Defaults to 0 (infinite recursion) unless specified.
        [Parameter(Mandatory = $false, Position = 2)]
        [Alias('d')]
        [int]$Depth = 0,

        # Filter to show only folders in the output.
        # [switch]: If present, Get-ChildItem will be told to ignore files.
        [Parameter(Mandatory = $false)]
        [Alias('do')]
        [switch]$DirectoryOnly
    )

    process {
        # Logic: If the 'Path' provided doesn't actually exist on the disk,
        # AND it matches one of our style keywords, we assume the user meant:
        # 'Get-Tree -Style <keyword>' instead of 'Get-Tree -Path <keyword>'.

        # Defines a list of keywords that we recognize as 'Styles' instead of 'Paths'.
        $StyleKeywords = @('classic', 'modern', 'visual', 'c', 'm', 'v')
        if (-not (Test-Path -Path $Path) -and ($StyleKeywords -contains $Path.ToLower())) {
            $Style = $Path # Shift the input over to the Style variable
            $Path = "." # Default the path back to the current directory
        }

        try {
            # Resolve-Path converts relative paths (like '..') or paths with wildcards
            # into absolute filesystem paths. -ErrorAction Stop triggers the catch block if it fails.
            $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop

            # We use .Path to ensure we have the string literal path,
            # avoiding issues with provider-prefixed paths (like 'Microsoft.PowerShell.Core\FileSystem::C:\...')
            $RootPath = $ResolvedPath.Path
        }
        catch {
            # Graceful exit if the directory doesn't exist and isn't a recognized style keyword.
            Write-Error "Could not find path: $Path"
            return
        }

        # .treeignore Logic

        # 1. Define the location of the .treeignore file relative to the root being scanned.
        $IgnoreFile = Join-Path $RootPath ".treeignore"

        # 2. Initialize the list with "Hardcoded" ignores.
        # You always want to hide the tool's own config and the heavy .git folder.
        $IgnoreList = @(".treeignore", ".git")

        # 3. Check if a local .treeignore file exists.
        if (Test-Path $IgnoreFile) {
            # 4. Read the file and clean up the entries.
            $IgnoreList += Get-Content $IgnoreFile |
                # Remove empty lines or lines with only whitespace
                Where-Object { $_ -match '\S' } |
                # Trim spaces and strip trailing slashes so matching is consistent
                ForEach-Object { $_.Trim().TrimEnd('\').TrimEnd('/') }
        }

        # Define the core parameters for the file system scan
        function Invoke-TreeRecursive {
            param(
                [string]$CurrentPath,
                [int]$CurrentDepth,
                [string]$Prefix,
                [int]$MaxDepth,
                [bool]$OnlyDirs
            )

            if ($MaxDepth -gt 0 -and $CurrentDepth -ge $MaxDepth) { return }

            $gciParams = @{ Path = $CurrentPath; Force = $true }
            if ($OnlyDirs) { $gciParams['Directory'] = $true }

            $Items = Get-ChildItem @gciParams | Where-Object {
                $item = $_
                $shouldIgnore = $false
                foreach ($pattern in $IgnoreList) {
                    if ($item.Name -like $pattern) { $shouldIgnore = $true; break }
                }
                !$shouldIgnore
            } | Sort-Object PSIsContainer, Name -Descending

            $Count = $Items.Count
            for ($i = 0; $i -lt $Count; $i++) {
                $item = $Items[$i]
                $isLast = ($i -eq $Count - 1)

                $c_mid = "$([char]0x251C)$([char]0x2500) " # ├─
                $c_end = "$([char]0x2514)$([char]0x2500) " # └─

                $symbol = switch -Wildcard ($Style) {
                    "m*" { if ($isLast) { $c_end } else { $c_mid } }
                    "v*" { if ($item.PSIsContainer) { "$([char]0xD83D)$([char]0xDCC1) " } else { "$([char]0xD83D)$([char]0xDCC4) " } }
                    Default { if ($item.PSIsContainer) { "+ " } else { "- " } }
                }

                [void]$script:report.AppendLine("$Prefix$symbol$($item.Name)")

                if ($item.PSIsContainer) {
                    $indentChar = if ($Style -like "m*") { if ($isLast) { "    " } else { "$([char]0x2502)   " } }
                                  else { "  " }

                    $newPrefix = $Prefix + $indentChar
                    Invoke-TreeRecursive -CurrentPath $item.FullName -CurrentDepth ($CurrentDepth + 1) -Prefix $newPrefix -MaxDepth $MaxDepth -OnlyDirs $OnlyDirs
                }
            }
        }

        # Build the String
        $script:report = [System.Text.StringBuilder]::new()

        # Pass the parameters into the recursive function
        Invoke-TreeRecursive -CurrentPath $RootPath -CurrentDepth 0 -Prefix "" -MaxDepth $Depth -OnlyDirs $DirectoryOnly.IsPresent

        $finalTree = $script:report.ToString()
        $E = [char]27

        if ([string]::IsNullOrWhiteSpace($finalTree)) {
            if (-not $Quiet) { Write-Host "$E[33mNo items found in: $RootPath$E[0m" }
            return
        }

        if ($MyInvocation.ExpectingInput -or $PSCmdlet.MyInvocation.PipelineLength -gt 1 -or -not $Quiet) {
            Write-Output $finalTree
        }

        try {
            $finalTree | Set-Clipboard -ErrorAction Stop
            if (-not $Quiet) {
                Write-Host "${E}[32m${E}[3mCopied to clipboard${E}[0m"
            }
        }
        catch {
            if (-not $Quiet) { Write-Host "$E[33m$E[3mClipboard unavailable.$E[0m" }
        }
    }
}

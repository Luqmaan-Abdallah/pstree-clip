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
        [string]$Style = $Script:GetTreeDefaultStyle,

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
        $gciParams = @{
            Path    = $RootPath # The starting point we resolved earlier
            Recurse = $true # Go into subdirectories
            Force   = $true # Include hidden and system files (like .env or .gitignore)
        }
        # Check if the user specifically provided a 'Depth' argument.
        # We also ensure it's greater than 0, as Get-ChildItem -Depth 0 
        # would only show the root files.
        if ($PSBoundParameters.ContainsKey('Depth') -and $Depth -gt 0) { $gciParams['Depth'] = $Depth }

        # If the -DirectoryOnly switch was used, we add 'Directory' to our splat.
        # This tells Get-ChildItem to stop looking for files entirely, 
        # making the scan much faster.
        if ($DirectoryOnly) { $gciParams['Directory'] = $true }

        $allFiles = Get-ChildItem @gciParams | Where-Object {
            $item = $_

            # 1. Calculate the Relative Path
            # If Root is 'C:\Projects' and Item is 'C:\Projects\Node\index.js', 
            # this produces 'Node\index.js'
            $RelativePath = $item.FullName.Substring($RootPath.Length).TrimStart('\')

            # 2. Break the path into individual folder names
            # 'Node\index.js' becomes @('Node', 'index.js')
            $pathParts = $RelativePath -split '\\'
            
            $shouldIgnore = $false

            # 3. Check every pattern in your .treeignore list
            foreach ($pattern in $IgnoreList) {
                # Logic: Ignore if the filename matches the pattern (e.g., 'temp.log')
                # OR if any parent folder in the path matches the pattern (e.g., 'node_modules')
                if ($item.Name -like $pattern -or ($pathParts -contains $pattern)) {
                    $shouldIgnore = $true
                    break # Stop checking other patterns once we find a match
                }
            }

            # 4. Return the inverse (If shouldIgnore is false, keep the file)
            !$shouldIgnore
        } | Sort-Object FullName # Ensures the tree is alphabetical for a clean look

        # String Building

        # 1. Initialize a StringBuilder for high-performance string concatenation.
        $report = [System.Text.StringBuilder]::new()
        foreach ($item in $allFiles) {
            # 2. Get the path relative to the scan root to determine indentation.
            $RelativePath = $item.FullName.Substring($RootPath.Length).TrimStart('\')

            # Skip the root folder itself if it somehow ended up in the list.
            if ([string]::IsNullOrWhiteSpace($RelativePath)) { continue }

            # 3. Calculate how deep the file is.
            # 'folder\subfolder\file.txt' split by '\' has a count of 3. 
            # Depth is count - 1 (index starting at 0).
            $itemDepth = ($RelativePath -split '\\').Count - 1

            # 4. Create the indentation string (2 spaces per depth level).
            $Indent = "  " * $itemDepth

            # 5. Choose the prefix symbol based on the chosen Style.
            # Using -Wildcard ($Style) allows 'm', 'mod', or 'modern' to all match "m*".
            $symbol = switch -Wildcard ($Style) {
                # Modern: Uses Unicode box-drawing characters
                "m*" { if ($item.PSIsContainer) { "$([char]0x251C)$([char]0x2500) " } else { "$([char]0x2514)$([char]0x2500) " } }

                # Visual: Uses Folder (0xDCC1) and File (0xDCC4) emojis
                "v*" { if ($item.PSIsContainer) { "$([char]0xD83D)$([char]0xDCC1) " } else { "$([char]0xD83D)$([char]0xDCC4) " } }

                # Classic: The default fallback using + and -
                Default { if ($item.PSIsContainer) { "+ " } else { "- " } }
            }

            # 6. Assemble the line and append it to our report.
            # [void] suppresses the output of the AppendLine method itself.
            [void]$report.AppendLine("$Indent$symbol$($item.Name)")
        }

        # Finalization

        # 1. Finalize the StringBuilder into a single string.
        $finalTree = $report.ToString()

        # 2. Define the 'Escape' character for ANSI colors.
        # [char]27 is the ASCII escape code (ESC), used for terminal formatting.
        $E = [char]27

        # 3. Handle the "Empty Result" edge case.
        if ([string]::IsNullOrWhiteSpace($finalTree)) {
            # Only complain if the user didn't ask us to be quiet.
            # $E[33m sets the text to Yellow. $E[0m resets it.
            if (-not $Quiet) { Write-Host "$E[33mNo items found in: $RootPath$E[0m" }
            return
        }

        # We output the tree to the pipeline if:
        # - The command is receiving/sending data via pipes (| or >)
        # - OR the user has NOT enabled -Quiet.
        if ($MyInvocation.ExpectingInput -or $PSCmdlet.MyInvocation.PipelineLength -gt 1 -or -not $Quiet) {
            Write-Output $finalTree
        }

        try {
            # 1. Attempt to send the string to the system clipboard.
            # -ErrorAction Stop is vital here; it forces PowerShell to jump 
            # to the 'catch' block if the clipboard service is missing or locked.
            $finalTree | Set-Clipboard -ErrorAction Stop

            # 2. Provide visual confirmation in Green ($E[32m) and Italics ($E[3m).
            if (-not $Quiet) { Write-Host "$E[32m$E[3mCopied to clipboard$E[0m" }
        }
        catch {
            # 3. Fallback logic. 
            # If Set-Clipboard fails (e.g., in a headless environment),
            # we notify the user in Yellow ($E[33m) rather than crashing.
            if (-not $Quiet) { Write-Host "$E[33m$E[3mClipboard unavailable.$E[0m" }
        }
    }
}
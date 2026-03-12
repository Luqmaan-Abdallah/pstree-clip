function Update-TreeConfig {
<#
.SYNOPSIS
    Updates the default settings for the Clip-Tree session.

.DESCRIPTION
    Modifies the internal module state for the current PowerShell session. 
    This allows you to change the default tree style or silence status messages 
    without passing parameters to every 'Get-Tree' call.

.PARAMETER Style
    Sets the default visual style for the tree. 
    Options: 'Classic' (Default), 'Modern' (Unicode), or 'Visual' (Emoji).

.PARAMETER Quiet
    Sets the default 'Quiet' preference. 
    If $true, status messages like "Copied to clipboard" are suppressed by default.

.EXAMPLE
    Update-TreeConfig -Style Modern
    Sets the default tree style to use box-drawing characters for the rest of the session.

.EXAMPLE
    Update-TreeConfig -Quiet $true
    Ensures all future Get-Tree commands run silently unless output is explicitly requested.

.EXAMPLE
    Update-TreeConfig -Style Visual -Quiet $false
    Sets the default to Emoji style while keeping the "Copied to clipboard" confirmation visible.

.EXAMPLE
    Update-TreeConfig -WhatIf
    Uses the built-in -WhatIf parameter to see what defaults would be changed without applying them.

.LINK
    Get-Tree
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [Alias('s')]
        [ArgumentCompleter({
            param($CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters)
            
            $null = $CommandName, $ParameterName, $CommandAst, $FakeBoundParameters
            
            ('Classic', 'Modern', 'Visual') | Where-Object { $_ -like "$WordToComplete*" }
        })]
        [string]$Style,

        [Parameter(Position = 1)]
        [Alias('q')]
        [bool]$Quiet
    )

    # SupportsShouldProcess allows the user to use -WhatIf or -Confirm
    if ($PSCmdlet.ShouldProcess("Module Configuration", "Update Defaults")) {
        # We target the $Script: scope so these variables persist in the module's memory
        if ($PSBoundParameters.ContainsKey('Style')) { 
            $Script:GetTreeDefaultStyle = $Style 
            Write-Verbose "Default Style updated to: $Style"
        }
        
        if ($PSBoundParameters.ContainsKey('Quiet')) { 
            $Script:GetTreeDefaultQuiet = $Quiet 
            Write-Verbose "Default Quiet mode updated to: $Quiet"
        }
    }
}
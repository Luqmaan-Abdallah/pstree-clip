# --- Module Internal State ---
# These variables are scoped to the 'Script' (the module itself).
# They act as a memory bank that persists as long as the module is loaded.
$Script:GetTreeDefaultStyle = 'Classic'
$Script:GetTreeDefaultQuiet = $false

# --- Dynamic Loading (Dot-Sourcing) ---
# We look for all .ps1 files in the Public and Private folders.
$Public  = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"
$Private = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1"

# The '.' (dot) before the path executes the script in the current scope.
# This makes the functions inside those files available to the module.
foreach ($import in @($Public + $Private)) {
    . $import.FullName
}

# --- Initialization ---
# This runs the Win32/ANSI setup code we moved to the Private folder.
Initialize-Console

# --- Create Aliases explicitly in the module scope ---
Set-Alias -Name ct -Value Get-Tree -Scope Script -Description "Alias for Get-Tree"
Set-Alias -Name gt -Value Get-Tree -Scope Script -Description "Alias for Get-Tree"
Set-Alias -Name clip-tree -Value Get-Tree -Scope Script -Description "Alias for Get-Tree"

# --- Public Interface ---
# This is the 'Gatekeeper'. Only the items listed here are visible to the user.
# Anything in the 'Private' folder is NOT exported, keeping the module tidy.
Export-ModuleMember -Function Get-Tree, Update-TreeConfig -Alias gt, ct, clip-tree
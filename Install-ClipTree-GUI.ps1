Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$TargetDir = Join-Path $HOME "ClipTree"
$TargetScriptPath = Join-Path $TargetDir "ClipTree.ps1"
$CurrentScriptPath = Join-Path $PSScriptRoot "ClipTree.ps1"

$form = New-Object System.Windows.Forms.Form
$form.Text = "ClipTree Standard Installer"
$form.Size = New-Object System.Drawing.Size(400,280)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Standard Location: $TargetDir`n`nThis will copy the script to your User Profile and link the 'ct' alias to your PowerShell Profile."
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(350,80)
$form.Controls.Add($label)

$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "Install to User Profile"
$installBtn.Location = New-Object System.Drawing.Point(120,120)
$installBtn.Size = New-Object System.Drawing.Size(150,45)
$installBtn.BackColor = [System.Drawing.Color]::LightGreen

$installBtn.Add_Click({
    if (!(Test-Path $CurrentScriptPath)) {
        [System.Windows.Forms.MessageBox]::Show("Error: ClipTree.ps1 not found in current folder!", "Error")
        return
    }

    if (!(Test-Path $TargetDir)) {
        New-Item -Path $TargetDir -ItemType Directory -Force
    }
    
    Copy-Item -Path $CurrentScriptPath -Destination $TargetScriptPath -Force

    $LoaderLine = ". `"$TargetScriptPath`""
    
    $ProfileDir = Split-Path $PROFILE
    if (!(Test-Path $ProfileDir)) { New-Item -Path $ProfileDir -ItemType Directory -Force }
    if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }

    $content = Get-Content $PROFILE
    $newContent = $content | Where-Object { $_ -notlike "*pstree-clip.ps1*" -and $_ -notlike "*ClipTree.ps1*" }
    $newContent | Set-Content $PROFILE

    Add-Content -Path $PROFILE -Value "`n$LoaderLine"

    [System.Windows.Forms.MessageBox]::Show("Installation Complete!`n`nScript copied to: $TargetDir`n`nPlease restart PowerShell. Type 'ct' or 'cliptree' to use.", "Success")
    $form.Close()
})
$form.Controls.Add($installBtn)

$editBtn = New-Object System.Windows.Forms.Button
$editBtn.Text = "Custom Edit Profile"
$editBtn.Location = New-Object System.Drawing.Point(120,180)
$editBtn.Size = New-Object System.Drawing.Size(150,30)
$editBtn.Add_Click({ notepad $PROFILE })
$form.Controls.Add($editBtn)

$form.ShowDialog() | Out-Null
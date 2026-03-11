Add-Type -AssemblyName PresentationFramework, System.Windows.Forms

$TargetDir = Join-Path $HOME "Clip-Tree"
$TargetScriptPath = Join-Path $TargetDir "Clip-Tree.ps1"
$CurrentScriptPath = Join-Path $PSScriptRoot "Clip-Tree.ps1"

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Clip-Tree" Height="480" Width="440" 
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        AllowsTransparency="True" WindowStyle="None" Background="Transparent">
    
    <Border Background="#0A0A0A" BorderBrush="#333333" BorderThickness="1" CornerRadius="20">
        <Grid Margin="40">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <RowDefinition Height="180"/>  <RowDefinition Height="Auto"/> <RowDefinition Height="Auto"/> </Grid.RowDefinitions>

            <Button Name="ExitBtn" Grid.Row="0" HorizontalAlignment="Right" VerticalAlignment="Top" 
                    Background="Transparent" BorderThickness="0" 
                    Margin="0,-25,-20,0" Cursor="Hand" Width="45" Height="45">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Grid Background="Transparent">
                            <Path Name="XMark" Data="M 0,0 L 12,12 M 12,0 L 0,12" 
                                  Stretch="Uniform" Width="14" Height="14"
                                  Stroke="#FFFFFF" StrokeThickness="2.5" />
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="XMark" Property="Stroke" Value="#FF4444"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Button.Template>
            </Button>

            <StackPanel Grid.Row="0">
                <TextBlock Text="Clip-Tree" FontSize="36" FontWeight="Bold" Foreground="#FFFFFF" />
                <TextBlock Text="POWERSHELL SETUP" FontSize="9" FontWeight="Black" Foreground="#444444" Margin="2,0,0,20"/>
            </StackPanel>
            
            <Grid Grid.Row="1">
                <TextBlock Name="DescText" TextWrapping="Wrap" FontSize="14" Foreground="#888888" LineHeight="20" Visibility="Visible">
                    Copy your folder structure as a clean text tree. Use it to give context when chatting with LLMs or when you need to generate documentation quickly.
                </TextBlock>

                <StackPanel Name="UsagePanel" Visibility="Collapsed">
                    <TextBlock Text="FINISHED" FontSize="10" FontWeight="Bold" Foreground="#00FF41" Margin="0,0,0,15"/>
                    <TextBlock Text="Everything is set up. Click 'DONE' to exit. You can now use this command in any new terminal window:" 
                               TextWrapping="Wrap" FontSize="14" Foreground="#888888" LineHeight="20" Margin="0,0,0,15"/>
                    <TextBlock Text="Clip-Tree" FontSize="20" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,5"/>
                    <TextBlock Text="Aliases: ct, clip-tree" FontSize="13" Foreground="#555555" />
                </StackPanel>
            </Grid>
            
            <StackPanel Grid.Row="2" Margin="0,20,0,0">
                <Button Name="InstallBtn" Content="ADD TO POWERSHELL" Height="55" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Name="box" Background="#FFFFFF" CornerRadius="8">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center">
                                    <ContentPresenter.Resources>
                                        <Style TargetType="TextBlock">
                                            <Setter Property="Foreground" Value="#000000"/>
                                            <Setter Property="FontWeight" Value="Bold"/>
                                            <Setter Property="FontSize" Value="13"/>
                                        </Style>
                                    </ContentPresenter.Resources>
                                </ContentPresenter>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="box" Property="Background" Value="#DDDDDD"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </StackPanel>

            <Button Name="EditBtn" Grid.Row="3" Content="OPEN PROFILE IN NOTEPAD" Margin="0,25,0,0" 
                    Background="Transparent" BorderThickness="0" Cursor="Hand">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <TextBlock Name="txt" Text="{TemplateBinding Content}" HorizontalAlignment="Center" 
                                   Foreground="#444444" FontSize="10" FontWeight="Bold" />
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="txt" Property="Foreground" Value="#888888"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Button.Template>
            </Button>
        </Grid>
    </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

$InstallBtn = $Window.FindName("InstallBtn")
$UsagePanel = $Window.FindName("UsagePanel")
$DescText   = $Window.FindName("DescText")
$ExitBtn    = $Window.FindName("ExitBtn")
$EditBtn    = $Window.FindName("EditBtn")

$Window.Add_MouseDown({ if ($_.ChangedButton -eq "Left") { $Window.DragMove() } })
$ExitBtn.Add_Click({ $Window.Close() })
$EditBtn.Add_Click({ notepad $PROFILE })

# --- Installation Logic ---
$InstallBtn.Add_Click({
    if ($InstallBtn.Content -eq "DONE") {
        $Window.Close()
        return
    }

    try {
        if (-not (Test-Path $CurrentScriptPath)) { throw "Clip-Tree.ps1 not found." }

        if (-not (Test-Path $TargetDir)) { New-Item $TargetDir -ItemType Directory -Force | Out-Null }
        Copy-Item $CurrentScriptPath $TargetScriptPath -Force
        
        $LoaderLine = ". `"$TargetScriptPath`""
        $CleanContent = (Get-Content $PROFILE -ErrorAction SilentlyContinue) | Where-Object { $_ -notlike "*Clip-Tree.ps1*" }
        $CleanContent + "`n$LoaderLine" | Set-Content $PROFILE

        $DescText.Visibility = "Collapsed"
        $UsagePanel.Visibility = "Visible"
        
        $InstallBtn.Content = "DONE"
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
    }
})

$Window.ShowDialog() | Out-Null
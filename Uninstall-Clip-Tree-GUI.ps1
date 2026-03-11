Add-Type -AssemblyName PresentationFramework, System.Windows.Forms

$TargetDir = Join-Path $HOME "Clip-Tree"
$TargetScriptPath = Join-Path $TargetDir "Clip-Tree.ps1"

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Clip-Tree Uninstaller" Height="480" Width="440" 
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        AllowsTransparency="True" WindowStyle="None" Background="Transparent">
    
    <Border Background="#0A0A0A" BorderBrush="#333333" BorderThickness="1" CornerRadius="20">
        <Grid Margin="40">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> 
                <RowDefinition Height="180"/>  
                <RowDefinition Height="Auto"/> 
                <RowDefinition Height="Auto"/> 
            </Grid.RowDefinitions>

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
                <TextBlock Text="UNINSTALLER" FontSize="9" FontWeight="Black" Foreground="#444444" Margin="2,0,0,20"/>
            </StackPanel>
            
            <Grid Grid.Row="1">
                <TextBlock Name="DescText" TextWrapping="Wrap" FontSize="14" Foreground="#888888" LineHeight="20" Visibility="Visible">
                    This will remove the Clip-Tree source files and delete the profile hooks. 
                    Deactivating: Clip-Tree, ct, and clip-tree.
                </TextBlock>

                <StackPanel Name="UsagePanel" Visibility="Collapsed">
                    <TextBlock Text="REMOVAL COMPLETE" FontSize="10" FontWeight="Bold" Foreground="#FF4444" Margin="0,0,0,15"/>
                    <TextBlock Text="The following commands have been deactivated:" 
                               FontSize="12" Foreground="#888888" Margin="0,0,0,10"/>
                    <TextBlock Text="Clip-Tree, ct, clip-tree" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,0,15"/>
                    <TextBlock Text="Click 'DONE' to exit. Restart terminal to clear memory." 
                               TextWrapping="Wrap" FontSize="13" Foreground="#555555" LineHeight="18"/>
                </StackPanel>
            </Grid>
            
            <StackPanel Grid.Row="2" Margin="0,20,0,0">
                <Button Name="UninstallBtn" Content="REMOVE CLIP-TREE" Height="55" Cursor="Hand">
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

$UninstallBtn = $Window.FindName("UninstallBtn")
$UsagePanel   = $Window.FindName("UsagePanel")
$DescText     = $Window.FindName("DescText")
$ExitBtn      = $Window.FindName("ExitBtn")
$EditBtn      = $Window.FindName("EditBtn")

$Window.Add_MouseDown({ if ($_.ChangedButton -eq "Left") { $Window.DragMove() } })
$ExitBtn.Add_Click({ $Window.Close() })
$EditBtn.Add_Click({ notepad $PROFILE })

# --- Uninstallation Logic ---
$UninstallBtn.Add_Click({
    if ($UninstallBtn.Content -eq "DONE") {
        $Window.Close()
        return
    }

    try {
        if (Test-Path $PROFILE) {
            $content = Get-Content $PROFILE -ErrorAction SilentlyContinue
            $newContent = $content | Where-Object { 
                $_ -notlike "*Clip-Tree.ps1*" -and 
                $_ -notlike "*pstree-clip.ps1*" 
            }
            $newContent | Set-Content $PROFILE -Force
        }

        if (Test-Path $TargetDir) {
            Remove-Item -Path $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        $DescText.Visibility = "Collapsed"
        $UsagePanel.Visibility = "Visible"
        $UninstallBtn.Content = "DONE"
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)")
    }
})

$Window.ShowDialog() | Out-Null
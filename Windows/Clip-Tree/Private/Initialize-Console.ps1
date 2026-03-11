function Initialize-Console {
    # 1. Targeted Execution
    # We only run this if we are in a standard Console and using legacy PowerShell (v5).
    # PowerShell 7+ and VS Code handle ANSI colors automatically.
    if ($Host.Name -eq 'ConsoleHost' -and $PSVersionTable.PSVersion.Major -le 5) {

        # 2. C# Signature (P/Invoke)
        # We define a piece of C# code to talk directly to the Windows Kernel (kernel32.dll).
        $Signature = @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@

        # 3. Inject the Type
        # Add-Type compiles this C# on the fly so PowerShell can use it.
        Add-Type -MemberDefinition $Signature -Name "Win32Utils" -Namespace "TreeUtils" -PassThru -ErrorAction SilentlyContinue | Out-Null
        
        $type = [TreeUtils.Win32Utils]
        if ($type) {
            # 4. Enable VT Processing
            # -11 is the constant for the standard output handle (STDOUT).
            $handle = $type::GetStdHandle(-11)
            $mode = 0

            # 0x0004 is the flag for ENABLE_VIRTUAL_TERMINAL_PROCESSING.
            # We use '-bor' (Bitwise OR) to add this flag without losing existing console settings.
            if ($type::GetConsoleMode($handle, [ref]$mode)) {
                [void]$type::SetConsoleMode($handle, $mode -bor 0x0004)
            }
        }
    }
}
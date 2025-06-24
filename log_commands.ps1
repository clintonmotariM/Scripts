# Define the log file path
$logFile = "D:\scripts\PowerShellLogs\command_history.txt"

# Override the built-in prompt function to log each command
function prompt {
    $lastCommand = Get-History -Count 1
    if ($lastCommand) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp`t$($lastCommand.CommandLine)"
        
        # Prevent duplicate entries by checking last line of file
        if (!(Get-Content $logFile -Tail 1 | Select-String -SimpleMatch $logEntry)) {
            $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
        }
    }
    return "PS " + $(Get-Location) + "> "
}

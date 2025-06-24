# ==========================================
# Script: uninstall_duplicates.ps1
# Features:
# ✅ Safe uninstalling (keeps latest version)
# ✅ Smart filtering (whitelist/blacklist)
# ✅ Deep duplicate detection
# ✅ Logging with timestamped output
# ✅ Dry run support
# ✅ Scheduler-ready
# ==========================================

# === CONFIGURATION ===
$dryRun = $true  # Change to $false to actually uninstall
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "D:\scripts\PowerShellLogs\uninstall_log_$timestamp.txt"

# Programs to always skip
$whitelist = @("Visual Studio", "Windows SDK")

# Programs to uninstall even if latest
$blacklist = @()  # e.g., @("ToolX")

# === LOG FUNCTION ===
function Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$time][$level] $message"
    Write-Host $line
    $line | Out-File -FilePath $logFile -Append -Encoding utf8
}

# === MAIN PROCESS ===
Log "=== Starting duplicate program cleanup ==="

# Collect installed programs
$programs = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -and $_.Version }
$grouped = $programs | Group-Object Name | Where-Object { $_.Count -gt 1 }

foreach ($group in $grouped) {
    $name = $group.Name
    $sorted = $group.Group | Sort-Object Version
    $latest = $sorted[-1]
    $toRemove = $sorted[0..($sorted.Count - 2)]

    foreach ($entry in $toRemove) {
        $entryName = $entry.Name.Trim()
        $version = $entry.Version

        if ($whitelist | Where-Object { $entryName -like "*$_*" }) {
            Log "Skipped (whitelisted): ${entryName} ${version}" "INFO"
            continue
        }

        if ($blacklist.Count -gt 0 -and !($blacklist | Where-Object { $entryName -like "*$_*" })) {
            Log "Skipped (not in blacklist): ${entryName} ${version}" "INFO"
            continue
        }

        if ($dryRun) {
            Log "DRY RUN: Would uninstall ${entryName} ${version}" "WARNING"
        } else {
            try {
                Log "Attempting to uninstall ${entryName} ${version}..." "INFO"
                $result = $entry.Uninstall()
                if ($result.ReturnValue -eq 0) {
                    Log "Successfully uninstalled ${entryName} ${version}" "INFO"
                } else {
                    Log "Failed to uninstall ${entryName} ${version} (code: $($result.ReturnValue))" "ERROR"
                }
            } catch {
                $errMsg = $_.Exception.Message
                Log "Error uninstalling ${entryName} ${version}: $errMsg" "ERROR"
            }
        }
    }
}

# === SUMMARY ===
Log "Cleanup Summary: $($grouped.Count) duplicate program(s) processed." "INFO"
Log "=== Duplicate cleanup completed ===" "INFO"

# === OPTIONAL: Task Scheduler ===
<# 
To schedule this script:
1. Open Task Scheduler
2. Create Task > Triggers: Monthly
3. Action: Start a program
4. Program: powershell.exe
5. Arguments: -ExecutionPolicy Bypass -File "D:\scripts\PowerShellLogs\uninstall_duplicates.ps1"
#>

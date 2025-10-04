#Stop process shift.exe
Get-Process -Name 'shift*' -ErrorAction SilentlyContinue |
  Stop-Process -Force -ErrorAction SilentlyContinue

# Cleanup Shift files for the current logged-in user

$user_list = Get-ChildItem C:\Users | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty Name
foreach ($user in $user_list) {
    if ($user -notlike "*Public*") {
        $paths = @(
			"C:\Users\$user\AppData\Local\Temp\is-*\Shift*"
            "C:\Users\$user\AppData\Local\Shift",
			"C:\Users\$user\OneDrive*\Bureau\Shift Browser.lnk",
            "C:\Users\$user\OneDrive*\Desktop\Shift Browser.lnk",
			"C:\Users\$user\Downloads\Shift - *.exe",
			"C:\Users\$user\OneDrive*\Downloads\Shift - *.exe"
            "C:\Users\$user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Shift\Shift Browser.lnk",
            "C:\Users\$user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Shift.lnk"
        )

        foreach ($path in $paths) {
            if (Test-Path -Path $path) {
                Remove-Item -Path $path -Recurse -Force
                if (Test-Path -Path $path) {
                    Write-Host "Failed to remove ShiftBrowser -> $path"
                } else {
                    Write-Host "Removed -> $path"
                }
            } else {
                Write-Host "Not found -> $path"
            }
        }
    }
}

# Delete Shift-related registry keys for all loaded user hives
$registryPathsHKCU = @(
    "HKCU:\Software\Shift",
    "HKCU:\SOFTWARE\Clients\StartMenuInternet\Shift",
    "HKCU:\Software\Classes\ShiftHTML"
)

foreach ($regPath in $registryPathsHKCU) {
    if (Test-Path $regPath) {
        Remove-Item $regPath -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $regPath) { Write-Host "Failed -> $regPath" } else { Write-Host "Removed -> $regPath" }
    } else {
        Write-Host "Not found -> $regPath"
    }
}

 # HKCU Run cleanup for ShiftAutoLaunch_*
$pattern = 'ShiftAutoLaunch_*'

Get-ChildItem 'Registry::HKEY_USERS' |
  Where-Object { $_.Name -match '^HKEY_USERS\\S-1-12-1' -or $_.Name -match '^HKEY_USERS\\S-1-5-21' } |  # filter to user SIDs
  ForEach-Object {
    $sidPath = "Registry::$($_.Name)\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $sidPath) {
        $rk = Get-Item -LiteralPath $sidPath
        $matches = $rk.GetValueNames() | Where-Object { $_ -like $pattern }
        foreach ($name in $matches) {
            Remove-ItemProperty -LiteralPath $sidPath -Name $name -Force -ErrorAction SilentlyContinue
            Write-Host "Removed $name from $sidPath"
        }
    }
}
# ---- Shift scheduled task cleanup (preview mode via -WhatIf) ----
$taskName = 'ShiftLaunchTask'
$taskFile = "C:\Windows\System32\Tasks\$taskName"
if (Test-Path -LiteralPath $taskFile) {
    Remove-Item -LiteralPath $taskFile -Force
    if (Test-Path -LiteralPath $taskFile) {
        Write-Host "Still present (preview mode) -> $taskFile"
    } else {
        Write-Host "Removed task file -> $taskFile"
    }
} else {
    Write-Host "Task file not found -> $taskFile"
}

# ---- Remove Task Scheduler cache entries for "ShiftLaunchTask" ----

$taskCacheKeys = @(
    "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\ShiftLaunchTask"
)
foreach ($taskCacheKey in $taskCacheKeys) {
    if (Test-Path -Path $taskCacheKey) {
        Remove-Item -Path $taskCacheKey -Recurse -ErrorAction SilentlyContinue
    }
}

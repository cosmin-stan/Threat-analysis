# Cleanup Shift files for the current logged-in user

$user = $env:USERNAME   # Gets current user name

$paths = @(
    "C:\Users\$user\AppData\Local\Shift",
    "C:\Users\$user\Desktop\Shift Browser.lnk",
    "C:\Users\$user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Shift Browser.lnk",
    "C:\Users\$user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Shift.lnk"
)

foreach ($path in $paths) {
    if (Test-Path -Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path -Path $path) {
            Write-Host "Failed to remove -> $path"
        } else {
            Write-Host "Removed -> $path"
        }
    } else {
        Write-Host "Not found -> $path"
    }
}

# Delete installers from Downloads: "Shift - *.exe"
$installers = @()
$installers = Get-ChildItem -Path "C:\Users\$user\Downloads" -Filter "Shift - *.exe" -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }

foreach ($installer in $installers) {
    if (Test-Path -Path $installer) {
        Remove-Item -Path $installer -Force -ErrorAction SilentlyContinue
        if (Test-Path -Path $installer) {
            Write-Host "Failed to remove Shift installer -> $installer"
        } else {
            Write-Host "Removed Shift installer -> $installer"
        }
    } else {
        Write-Host "Not found (installer) -> $installer"
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
$runKey   = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'
$pattern  = 'ShiftAutoLaunch_*'

# Show what's there (names and data) so you can verify
if (Test-Path -LiteralPath $runKey) {
    $rk = Get-Item -LiteralPath $runKey
    $allNames = @($rk.GetValueNames())            # <-- force array
    $matches  = @($allNames | Where-Object { $_ -like $pattern })

    Write-Host "Found Run values:"; $allNames | ForEach-Object { " - $_ = " + ($rk.GetValue($_)) }
    if ($matches.Count -gt 0) {
        Write-Host "Matched pattern '$pattern': $($matches -join ', ')"
        foreach ($name in $matches) {
            Remove-ItemProperty -LiteralPath $runKey -Name $name -Force
            # For real deletion, remove -WhatIf
        }
    } else {
        Write-Host "No values matching pattern '$pattern' under $runKey"
    }

    # Also try the specific one you saw (explicit delete)
    $exact = 'ShiftAutoLaunch_13750E1B0E0BBA4F0FAA294CDD87708D'
    if ($allNames -contains $exact) {
        Remove-ItemProperty -LiteralPath $runKey -Name $exact -Force
    }
} else {
    Write-Host "Run key not found: $runKey"
}
# ---- Shift scheduled task cleanup (preview mode via -WhatIf) ----
$taskName = 'ShiftLaunchTask'
$taskFile = "C:\Windows\System32\Tasks\$taskName"
if (Test-Path -LiteralPath $taskFile) {
    Remove-Item -LiteralPath $taskFile -Force -WhatIf
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
    "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{E88F1AB4-6648-4E46-8256-20EBDB550948}",
    "Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\ShiftLaunchTask"
)
foreach ($taskCacheKey in $taskCacheKeys) {
    if (Test-Path -Path $taskCacheKey) {
        Remove-Item -Path $taskCacheKey -Recurse -ErrorAction SilentlyContinue
    }
}

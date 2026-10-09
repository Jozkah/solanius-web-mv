# Keeps the local web-mv relay alive on 127.0.0.1:9000.
# Prefer `bun run` over the compiled exe (more reliable on this machine).
# Leave this PowerShell window open while using the memory viewer.
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$relayDir = Join-Path $root "relay"
$bunCandidates = @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Oven-sh.Bun_Microsoft.Winget.Source_8wekyb3d8bbwe\bun-windows-x64\bun.exe",
    "$env:USERPROFILE\.bun\bin\bun.exe",
    "C:\Program Files\Bun\bun.exe"
)
$bun = $bunCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $bun) {
    $cmd = Get-Command bun -ErrorAction SilentlyContinue
    if ($cmd) { $bun = $cmd.Source }
}
if (-not $bun) {
    Write-Host "Bun not found. Install from https://bun.sh then re-run."
    exit 1
}
if (-not (Test-Path (Join-Path $relayDir "src\index.ts"))) {
    Write-Host "Missing relay sources in $relayDir"
    exit 1
}

$logDir = Join-Path $env:TEMP "solanius-web-mv"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

Write-Host "Solanius web-mv relay watchdog"
Write-Host "Bun: $bun"
Write-Host "URL: http://127.0.0.1:9000"
Write-Host "Leave this window open. Ctrl+C to stop."
Write-Host ""

function Stop-Port9000 {
    Get-NetTCPConnection -LocalPort 9000 -ErrorAction SilentlyContinue |
        ForEach-Object { try { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } catch {} }
    Get-Process bun-server -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

while ($true) {
    Stop-Port9000
    Start-Sleep -Milliseconds 500

    $out = Join-Path $logDir "relay-out.log"
    $err = Join-Path $logDir "relay-err.log"
    Remove-Item $out, $err -Force -ErrorAction SilentlyContinue
    $uiDir = Join-Path $root "release\public"
    if (-not (Test-Path (Join-Path $uiDir "index.html"))) {
        $uiDir = Join-Path $root "frontend\dist"
    }
    Write-Host ("[{0}] starting bun run src/index.ts (UI_DIR={1})" -f (Get-Date -Format "HH:mm:ss"), $uiDir)
    $env:UI_DIR = $uiDir
    $p = Start-Process -FilePath $bun -ArgumentList @("run", "src/index.ts") -WorkingDirectory $relayDir `
        -PassThru -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err

    $up = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 200
        if ($p.HasExited) { break }
        try {
            $r = Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:9000/status" -TimeoutSec 1
            Write-Host ("[{0}] up: {1}" -f (Get-Date -Format "HH:mm:ss"), $r.Content.Trim())
            $up = $true
            break
        } catch {}
    }
    if (-not $up) {
        Write-Host ("[{0}] failed to come up (exit={1})" -f (Get-Date -Format "HH:mm:ss"), $p.ExitCode)
        if (Test-Path $err) { Get-Content $err -Tail 30 | ForEach-Object { Write-Host "  $_" } }
        if (Test-Path $out) { Get-Content $out -Tail 30 | ForEach-Object { Write-Host "  $_" } }
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 2
        continue
    }

    while (-not $p.HasExited) { Start-Sleep -Seconds 2 }

    Write-Host ("[{0}] relay exited code={1}. Restarting in 1s..." -f (Get-Date -Format "HH:mm:ss"), $p.ExitCode)
    if (Test-Path $err) { Get-Content $err -Tail 20 | ForEach-Object { Write-Host "  err: $_" } }
    Start-Sleep -Seconds 1
}

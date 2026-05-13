# check_history.ps1 - Verify XAUUSDm history is loaded for backtest range
#
# Run this after manually downloading history in MT5 to confirm coverage.

[CmdletBinding()]
param(
    [string]$Symbol = 'XAUUSDm',
    [string]$Broker = 'Exness-MT5Trial17',
    [int]   $FromYear = 2020,
    [int]   $ToYear   = 2026
)

$HIST = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\bases\$Broker\history\$Symbol"

Write-Host "History check for $Symbol on $Broker"
Write-Host "Path: $HIST"
Write-Host ""

if (-not (Test-Path $HIST)) {
    Write-Host "FAIL: History folder doesn't exist. Download history in MT5 first." -ForegroundColor Red
    exit 1
}

$files = Get-ChildItem $HIST -Filter '*.hcc'
if ($files.Count -eq 0) {
    Write-Host "FAIL: No .hcc files. Open chart of $Symbol in MT5 and scroll left (Home key)." -ForegroundColor Red
    exit 1
}

Write-Host "Found $($files.Count) history files:"
$missing = @()
for ($y = $FromYear; $y -le $ToYear; $y++) {
    $f = $files | Where-Object { $_.Name -eq "$y.hcc" }
    if ($f) {
        $sizeMB = [math]::Round($f.Length / 1MB, 2)
        $color = if ($f.Length -gt 1MB) { 'Green' } else { 'Yellow' }
        Write-Host ("  {0}.hcc  {1,8} MB  {2}" -f $y, $sizeMB, $f.LastWriteTime) -ForegroundColor $color
        if ($f.Length -lt 1MB) {
            Write-Host "    WARNING: file is small ($($f.Length) bytes) - history may be sparse" -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  {0}.hcc  MISSING" -f $y) -ForegroundColor Red
        $missing += $y
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "OK: history files present for $FromYear-$ToYear" -ForegroundColor Green
    Write-Host "Note: this only checks M15 (and other M1-based TFs share the same .hcc)." -ForegroundColor DarkGray
    Write-Host "      H1 history is also synthesized from M1 data, no separate file needed." -ForegroundColor DarkGray
    exit 0
} else {
    Write-Host "MISSING years: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "In MT5: open XAUUSDm chart, press Home, wait for history to load." -ForegroundColor Yellow
    exit 1
}

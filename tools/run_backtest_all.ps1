# run_backtest_all.ps1 - Automate Strategy Tester runs for all 4 variants
#
# Usage:
#   .\run_backtest_all.ps1                        # full 4 variants, 2020-2024
#   .\run_backtest_all.ps1 -SmokeTest             # quick: VARIANT_A only, 2024
#   .\run_backtest_all.ps1 -Symbol XAUUSDc        # override symbol
#   .\run_backtest_all.ps1 -FromDate 2023.01.01   # override start date
#
# Requires: MT5 already logged into broker; metaeditor64.exe at default path.

[CmdletBinding()]
param(
    [string]$Symbol         = 'XAUUSDm',
    [string]$Period         = 'M15',
    [string]$FromDate       = '2020.01.01',
    [string]$ToDate         = '2024.12.31',
    [int]   $Model          = 4,           # 0=Every tick, 1=1min OHLC, 2=Open prices, 4=Every tick based on real ticks
    [int]   $Deposit        = 10000,
    [int]   $Leverage       = 500,
    [string[]]$Variants     = @('A','B','C','D'),
    [switch]$SmokeTest,
    [int]   $TimeoutMinutes = 120
)

$ErrorActionPreference = 'Stop'

# --- Paths --------------------------------------------------------------------
$MT5_INSTALL = 'C:\Program Files\MetaTrader 5'
$TERMINAL    = "$MT5_INSTALL\terminal64.exe"
$METAEDITOR  = "$MT5_INSTALL\metaeditor64.exe"
$MT5_DATA    = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
$EXPERTS_DIR = "$MT5_DATA\MQL5\Experts"
$EA_REL_PATH = 'TrendPullbackEA_v1'    # path relative to MQL5\Experts, no extension
$EA_FULL     = "$EXPERTS_DIR\$EA_REL_PATH.mq5"

$REPO_ROOT   = Split-Path -Parent $PSScriptRoot   # tools\ -> repo root
$REPO_SRC    = Join-Path $REPO_ROOT 'src'
$REPORTS_DIR = Join-Path $REPO_ROOT "tests\backtest_reports\$(Get-Date -Format 'yyyy-MM-dd_HHmm')"

if ($SmokeTest) {
    $Variants = @('A')
    $FromDate = '2024.01.01'
    $ToDate   = '2024.06.30'
    Write-Host "[smoke-test] forcing VARIANT_A only, 2024H1 only" -ForegroundColor Yellow
}

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Backtest Orchestrator" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Symbol      : $Symbol"
Write-Host "Period      : $Period"
Write-Host "Date range  : $FromDate -> $ToDate"
Write-Host "Model       : $Model (4 = Every tick based on real ticks)"
Write-Host "Variants    : $($Variants -join ', ')"
Write-Host "Reports dir : $REPORTS_DIR"
Write-Host ""

# --- Sanity checks ------------------------------------------------------------
if (-not (Test-Path $TERMINAL))   { throw "terminal64.exe not found: $TERMINAL" }
if (-not (Test-Path $METAEDITOR)) { throw "metaeditor64.exe not found: $METAEDITOR" }
if (-not (Test-Path $REPO_SRC))   { throw "Repo src/ not found: $REPO_SRC" }

# Is MT5 already running? Tester needs sole control.
$running = Get-Process -Name terminal64 -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "WARNING: terminal64.exe is already running (PID $($running.Id))." -ForegroundColor Yellow
    Write-Host "         Strategy Tester needs sole control. Please close MT5 manually first." -ForegroundColor Yellow
    $resp = Read-Host "Continue anyway? (y/N)"
    if ($resp -ne 'y') { exit 1 }
}

# --- Step 1: Sync source from repo to MT5 + recompile -------------------------
Write-Host "[1/4] Syncing sources to MT5 + compiling..." -ForegroundColor Green
Copy-Item "$REPO_SRC\TrendPullbackEA_v1.mq5" -Destination "$EXPERTS_DIR\" -Force
New-Item -ItemType Directory -Path "$EXPERTS_DIR\include" -Force | Out-Null
Copy-Item "$REPO_SRC\include\*.mqh" -Destination "$EXPERTS_DIR\include\" -Force

$compileLog = "$env:TEMP\ea_compile.log"
if (Test-Path $compileLog) { Remove-Item $compileLog }
$p = Start-Process -FilePath $METAEDITOR `
    -ArgumentList "/compile:`"$EA_FULL`"", "/log:`"$compileLog`"" `
    -Wait -PassThru -WindowStyle Hidden
$logContent = if (Test-Path $compileLog) { Get-Content $compileLog -Encoding Unicode -Raw } else { '' }
if ($logContent -notmatch 'Result:\s*0\s*errors') {
    Write-Host $logContent
    throw "Compile failed. See log above."
}
$resultLine = ($logContent -split "`n" | Where-Object { $_ -match 'Result:' } | Select-Object -First 1).Trim()
Write-Host "      $resultLine" -ForegroundColor DarkGray

# --- Step 2: Create reports dir -----------------------------------------------
Write-Host "[2/4] Creating reports dir..." -ForegroundColor Green
New-Item -ItemType Directory -Path $REPORTS_DIR -Force | Out-Null

# --- Step 3: Run backtest per variant -----------------------------------------
$variantMap = @{ 'A' = 0; 'B' = 1; 'C' = 2; 'D' = 3 }
$results    = @()

foreach ($v in $Variants) {
    $vIdx       = $variantMap[$v]
    $reportPath = Join-Path $REPORTS_DIR "Variant_$v.htm"
    $iniPath    = Join-Path $REPORTS_DIR "Variant_$v.ini"

    $iniContent = @"
[Tester]
Expert=$EA_REL_PATH
Symbol=$Symbol
Period=$Period
Optimization=0
Model=$Model
ExecutionMode=0
FromDate=$FromDate
ToDate=$ToDate
ForwardMode=0
Deposit=$Deposit
Currency=USD
ProfitInPips=0
Leverage=$Leverage
ExecutionMode=0
Visual=0
Replace=1
ShutdownTerminal=1
UseLocal=1
Report=$reportPath

[TesterInputs]
InpStrategyVariant=$vIdx
InpTradingMode=1
InpEMA_Trend=200
InpEMA_Fast=50
InpEMA_Entry=20
InpRSI_Period=14
InpRSI_Oversold=30.0
InpRSI_Overbought=70.0
InpADX_Min=20.0
InpATR_Period=14
InpSL_ATR_Multiplier=1.5
InpTP_ATR_Multiplier=2.0
InpTrailing_ATR_Multiplier=1.0
InpRiskPercent=0.25
InpDailyLossCap=1.5
InpWeeklyLossCap=4.0
InpMaxDrawdown=12.0
InpMaxConsecutiveLosses=5
InpMaxTradesPerDay=6
InpCB_ATR_Lookback=20
InpCB_ATR_Multiplier=2.0
InpCB_SpreadThreshold=5.0
InpCB_PauseDuration=15
InpMaxSpreadPips=3.0
InpMaxSlippagePips=5
InpMinMarginLevel=200.0
InpFridayAutoClose=true
InpFridayCloseHour=21
InpUseBreakeven=true
InpBreakevenTriggerR=1.0
InpBreakevenOffset=0.5
InpUseTrailingStop=true
InpTrailingTriggerR=1.5
InpEnableLogging=true
"@

    # tester.ini must be UTF-16 LE with BOM (MT5 requirement)
    $utf16 = New-Object System.Text.UnicodeEncoding($false, $true)
    [System.IO.File]::WriteAllText($iniPath, $iniContent, $utf16)

    Write-Host ""
    Write-Host "[3/4] Running VARIANT_$v ..." -ForegroundColor Green
    Write-Host "      ini    : $iniPath"
    Write-Host "      report : $reportPath"
    $startTs = Get-Date

    $proc = Start-Process -FilePath $TERMINAL `
        -ArgumentList "/config:`"$iniPath`"" `
        -PassThru
    if (-not $proc.WaitForExit($TimeoutMinutes * 60 * 1000)) {
        Write-Host "      TIMEOUT after $TimeoutMinutes min - killing terminal64" -ForegroundColor Red
        Stop-Process -Id $proc.Id -Force
        $results += [pscustomobject]@{
            Variant = $v; Status = 'TIMEOUT'; Duration = $TimeoutMinutes * 60; Report = ''
        }
        continue
    }

    $dur = (Get-Date) - $startTs
    $reportExists = Test-Path $reportPath
    $status = if ($reportExists) { 'OK' } else { 'NO_REPORT' }
    Write-Host "      done   : $status ($([int]$dur.TotalSeconds)s)" `
        -ForegroundColor $(if ($reportExists) { 'Green' } else { 'Yellow' })
    $results += [pscustomobject]@{
        Variant  = $v
        Status   = $status
        Duration = [int]$dur.TotalSeconds
        Report   = if ($reportExists) { $reportPath } else { '' }
    }
}

# --- Step 4: Summary ----------------------------------------------------------
Write-Host ""
Write-Host "[4/4] Summary" -ForegroundColor Green
$results | Format-Table -AutoSize | Out-String | Write-Host

$summaryPath = Join-Path $REPORTS_DIR 'summary.txt'
$summary = @"
Backtest run: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Symbol: $Symbol  Period: $Period  Range: $FromDate -> $ToDate  Model: $Model
Deposit: \$$Deposit  Leverage: 1:$Leverage

"@
foreach ($r in $results) {
    $summary += "VARIANT_$($r.Variant): $($r.Status)  ($($r.Duration)s)  $($r.Report)`n"
}
[System.IO.File]::WriteAllText($summaryPath, $summary)
Write-Host "Summary written to: $summaryPath" -ForegroundColor Cyan

# Also copy CSV trade logs (written by EA's Logger to MQL5\Files)
$filesDir = "$MT5_DATA\MQL5\Files"
$csvLogs  = Get-ChildItem $filesDir -Filter 'Variant*_*.csv' -ErrorAction SilentlyContinue
if ($csvLogs) {
    Write-Host "Copying CSV trade logs..." -ForegroundColor DarkGray
    $csvLogs | ForEach-Object { Copy-Item $_.FullName "$REPORTS_DIR\" -Force }
    Write-Host "  $($csvLogs.Count) CSV files copied to $REPORTS_DIR" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "All done. Reports at: $REPORTS_DIR" -ForegroundColor Cyan

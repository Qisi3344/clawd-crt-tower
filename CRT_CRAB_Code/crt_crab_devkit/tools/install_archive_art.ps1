param([string]$GodotPath)
$ErrorActionPreference='Stop'
$projectPath=Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) { $GodotPath=Join-Path $projectPath '.tools\godot\Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Run tools/setup.ps1 or supply -GodotPath.' }
$cleanFar=Join-Path $projectPath 'assets\pixel\archive\source\far-clean.png'
if (-not (Test-Path -LiteralPath $cleanFar)) { throw 'The committed cleaned far-background production source is missing.' }
New-Item -ItemType Directory -Force -Path (Join-Path $projectPath 'artifacts') | Out-Null
Push-Location -LiteralPath $projectPath
try {
    foreach ($phase in @('compile','import')) {
        $runArguments=if ($phase -eq 'compile') { @('--headless','--path','.', '--script','tools/build_archive_art.gd') } else { @('--headless','--editor','--path','.', '--quit') }
        $logPath=Join-Path $projectPath "artifacts/archive-install-$phase.log"
        & $GodotPath @runArguments *> $logPath
        if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $logPath -Pattern '^SCRIPT ERROR:','^ERROR:')) { throw "Archive art $phase failed. See $logPath" }
    }
    Write-Output 'ARCHIVE artwork compiled and imported; level geometry was not changed.'
} finally { Pop-Location }

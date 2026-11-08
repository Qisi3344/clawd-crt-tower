param([string]$GodotPath)
$ErrorActionPreference='Stop'
$projectPath=Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) { $GodotPath=Join-Path $projectPath '.tools\godot\Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Run tools/setup.ps1 or supply -GodotPath.' }
foreach ($source in @('background/POPUP_far_source.png','mid-authored.png','terrain-material.png')) {
    if (-not (Test-Path -LiteralPath (Join-Path $projectPath "assets\pixel\popup\source\$source"))) { throw "Committed production source missing: $source" }
}
New-Item -ItemType Directory -Force -Path (Join-Path $projectPath 'artifacts') | Out-Null
Push-Location -LiteralPath $projectPath
try {
    foreach ($phase in @('compile','import')) {
        $runArguments=if ($phase -eq 'compile') { @('--headless','--path','.', '--script','tools/build_popup_art.gd') } else { @('--headless','--editor','--path','.', '--quit') }
        $logPath=Join-Path $projectPath "artifacts/popup-install-$phase.log"
        & $GodotPath @runArguments *> $logPath
        if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $logPath -Pattern '^SCRIPT ERROR:','^ERROR:')) { throw "Popup art $phase failed. See $logPath" }
    }
    Write-Output 'POP-UP artwork compiled and imported; level geometry was not changed.'
} finally { Pop-Location }

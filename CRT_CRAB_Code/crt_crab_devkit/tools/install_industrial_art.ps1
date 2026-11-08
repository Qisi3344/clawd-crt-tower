param([string]$GodotPath)
$ErrorActionPreference='Stop'
$projectPath=Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) { $GodotPath=Join-Path $projectPath '.tools\godot\Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Run tools/setup.ps1 or supply -GodotPath.' }
foreach ($key in @('recycle','signal')) {
    foreach ($source in @('mid-authored.png','far-authored.png','terrain-material.png')) {
        if (-not (Test-Path -LiteralPath (Join-Path $projectPath "assets\pixel\$key\source\$source"))) { throw "Production source missing: $key/$source" }
    }
}
New-Item -ItemType Directory -Force -Path (Join-Path $projectPath 'artifacts') | Out-Null
Push-Location -LiteralPath $projectPath
try {
    foreach ($phase in @('compile','import')) {
        $arguments=if ($phase -eq 'compile') { @('--headless','--path','.', '--script','tools/build_industrial_art.gd') } else { @('--headless','--editor','--path','.', '--quit') }
        $logPath=Join-Path $projectPath "artifacts/industrial-install-$phase.log"
        & $GodotPath @arguments *> $logPath
        if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $logPath -Pattern '^SCRIPT ERROR:','^ERROR:')) { throw "Industrial art $phase failed. See $logPath" }
    }
    Write-Output 'RECYCLE and SIGNAL art compiled and imported; original collision data retained.'
} finally { Pop-Location }

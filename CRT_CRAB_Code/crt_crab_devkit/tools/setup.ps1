$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$toolPath = Join-Path $projectPath '.tools'
$zipPath = Join-Path $toolPath 'godot.zip'
New-Item -ItemType Directory -Force -Path (Join-Path $toolPath 'godot') | Out-Null
# Official Godot release storage, linked by godotengine.org/download/archive/4.7.2-stable/.
$downloadUrl = 'https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip'
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
Expand-Archive -LiteralPath $zipPath -DestinationPath (Join-Path $toolPath 'godot') -Force
Write-Host 'Godot is ready. Open PLAY.cmd to play.'

param([switch]$QA, [switch]$Headless)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path $projectPath '.tools\godot\Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $enginePath)) {
    $foundEngine = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($foundEngine) { $enginePath = $foundEngine.Source }
    else { throw 'Godot not found. Install Godot 4.x or run tools/setup.ps1 first.' }
}
if (-not (Test-Path -LiteralPath (Join-Path $projectPath '.godot\global_script_class_cache.cfg'))) {
    & $enginePath --headless --editor --path $projectPath --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot project import failed.' }
}
$engineArguments = @('--path', $projectPath)
if ($Headless) { $engineArguments += '--headless' }
if ($QA) { $engineArguments += @('--', '--qa') }
& $enginePath @engineArguments
exit $LASTEXITCODE

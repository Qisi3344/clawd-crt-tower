param([switch]$Visual)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path -Parent $PSScriptRoot
$enginePath = Join-Path $projectPath '.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $enginePath)) { throw 'Run tools/setup.ps1 first.' }
Push-Location -LiteralPath $projectPath
try {
    $mode = if ($Visual) { 'visual' } else { 'headless' }
    $checks = @(
        @{ Name='state'; Arguments=@('--headless','--path','.', '--script','tests/six_link_state_qa.gd'); Report='six-link-state-qa.json' },
        @{ Name='menu'; Arguments=@('--path','.', '--fixed-fps','60','--','--qa','--menu-qa'); Report="stage2-qa-$mode.json" },
        @{ Name='story'; Arguments=@('--path','.', '--fixed-fps','60','--','--qa','--menu-qa','--story-qa'); Report="story-qa-$mode.json" },
        @{ Name='campaign'; Arguments=@('--path','.', '--fixed-fps','60','--','--qa','--chapter-qa'); Report="chapter-qa-$mode.json" },
        @{ Name='ecology'; Arguments=@('--path','.', '--fixed-fps','60','--','--qa','--ecology-qa'); Report="ecology-qa-$mode.json" },
        @{ Name='environment'; Arguments=@('--path','.', '--fixed-fps','60','--','--qa','--environment-qa'); Report="sideview-qa-$mode.json" }
    )
    foreach ($check in $checks) {
        $runArguments = $check.Arguments
        if (-not $Visual -and $check.Name -ne 'state') { $runArguments = @('--headless') + $runArguments }
        $logPath = Join-Path $projectPath "artifacts/verify-$($check.Name)-$mode.log"
        & $enginePath @runArguments *> $logPath
        $exit = $LASTEXITCODE
        $reportPath = Join-Path $projectPath "artifacts/$($check.Report)"
        $errors = Select-String -LiteralPath $logPath -Pattern '^SCRIPT ERROR:', '^ERROR:', '^FAIL '
        if ($exit -ne 0 -or $errors -or -not (Test-Path -LiteralPath $reportPath)) { throw "Check failed: $($check.Name). See $logPath" }
        $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        if (-not $report.passed) { throw "Report failed: $($check.Name). See $reportPath" }
        Write-Output "$($check.Name): PASS ($($report.tests.Count) checks)"
    }
} finally { Pop-Location }

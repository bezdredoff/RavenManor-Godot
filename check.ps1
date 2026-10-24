param(
	[Parameter(Mandatory = $true)][string]$GodotPath
)

$ErrorActionPreference = 'Stop'
$projectPath = $PSScriptRoot

function Invoke-GodotCheck {
	param([string]$Stage, [string[]]$Arguments, [string]$ExpectedOutput = '')
	$stdoutPath = [System.IO.Path]::GetTempFileName()
	$stderrPath = [System.IO.Path]::GetTempFileName()
	try {
		$process = Start-Process -FilePath $GodotPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
			-RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
		$stdout = Get-Content -LiteralPath $stdoutPath -Raw
		$stderr = Get-Content -LiteralPath $stderrPath -Raw
		if ($process.ExitCode -ne 0 -or $stderr -match 'SCRIPT ERROR:') {
			throw "$Stage failed.`n$stdout`n$stderr"
		}
		if ($ExpectedOutput -and -not $stdout.Contains($ExpectedOutput)) {
			throw "$Stage did not report '$ExpectedOutput'.`n$stdout`n$stderr"
		}
		Write-Output "$Stage passed."
	}
	finally {
		Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
	}
}

Invoke-GodotCheck 'Project import' @('--headless', '--editor', '--path', $projectPath, '--quit')
foreach ($script in @(
	'res://scripts/core/save_storage.gd',
	'res://scripts/raven/raven_ids.gd',
	'res://scripts/raven/raven_snapshot.gd',
	'res://scripts/raven/raven_reducer.gd',
	'res://scripts/raven/raven_campaign_store.gd',
	'res://scripts/raven/manor_navigation_graph.gd',
	'res://scripts/raven/manor_greybox.gd'
)) {
	Invoke-GodotCheck "Parse $script" @('--headless', '--check-only', '--path', $projectPath, '--script', $script)
}
Invoke-GodotCheck 'Raven foundation smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/raven_foundation_smoke.gd', '--quit-after', '120') 'Raven Manor foundation smoke passed'
Invoke-GodotCheck 'Raven navigation graph smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/manor_navigation_graph_smoke.gd', '--quit-after', '120') 'Raven Manor authored navigation graph smoke passed'

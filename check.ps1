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
	'res://scripts/raven/manor_greybox.gd',
	'res://scripts/raven/prototype_launcher.gd',
	'res://scripts/raven/foundation_lab.gd',
	'res://scripts/raven/raven_match3_game.gd',
	'res://scripts/shared/upds/match3_game.gd',
	'res://scripts/shared/upds/dialogue_paging.gd',
	'res://scripts/shared/upds/player_preferences.gd',
	'res://scripts/shared/upds/seeded_random.gd',
	'res://scripts/ui/css_motion.gd',
	'res://scripts/match3/match3_board_shape.gd',
	'res://scripts/match3/match3_tile_motion_layer.gd',
	'res://scripts/match3/match3_tutorials.gd',
	'res://scripts/raven/raven_menu_copy.gd',
	'res://scripts/raven/upds_match3_campaign_adapter.gd',
	'res://scripts/raven/raven_vn_player.gd',
	'res://scripts/raven/raven_production_localization.gd',
	'res://scripts/raven/hall_tea_vn.gd',
	'res://scripts/raven/raven_slice_director.gd',
	'res://scripts/raven/vertical_slice.gd',
	'res://scripts/raven/content_preview.gd',
	'res://scripts/raven/season1_map_greybox.gd'
)) {
	Invoke-GodotCheck "Parse $script" @('--headless', '--check-only', '--path', $projectPath, '--script', $script)
}
Invoke-GodotCheck 'Raven foundation smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/raven_foundation_smoke.gd', '--quit-after', '120') 'Raven Manor foundation smoke passed'
Invoke-GodotCheck 'Raven navigation graph smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/manor_navigation_graph_smoke.gd', '--quit-after', '120') 'Raven Manor authored navigation graph smoke passed'
Invoke-GodotCheck 'Prototype Lab smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/prototype_lab_smoke.gd', '--quit-after', '120') 'Raven Manor Prototype Lab smoke passed'
Invoke-GodotCheck 'UPDS engine port parity smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_core_reuse_smoke.gd', '--quit-after', '120') 'Raven Manor UPDS core reuse smoke passed'
Invoke-GodotCheck 'UPDS M3 visual primitives' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_match3_visual_primitives_smoke.gd', '--quit-after', '120') 'Raven Manor UPDS Match-3 visual primitives smoke passed'
Invoke-GodotCheck 'RM-VS-01 vertical slice smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vertical_slice_smoke.gd', '--quit-after', '120') 'Raven Manor RM-VS-01 smoke passed'

Invoke-GodotCheck 'Narrative production contract smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/production_narrative_smoke.gd', '--quit-after', '120') 'Raven Manor production narrative contract smoke passed'

Invoke-GodotCheck 'Layered Hall VN pilot smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/hall_tea_vn_smoke.gd', '--quit-after', '120') 'Raven Manor Hall tea VN pilot smoke passed'
Invoke-GodotCheck 'Hall VN runtime UI smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/hall_tea_vn_ui_smoke.gd', '--quit-after', '240') 'Raven Manor Hall VN UI runtime smoke passed'
Invoke-GodotCheck 'Whole season1 map smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/season1_map_smoke.gd', '--quit-after', '120') 'Raven Manor continuous season1 map smoke passed'

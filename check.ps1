param(
	[Parameter(Mandatory = $true)][string]$GodotPath
)

$ErrorActionPreference = 'Stop'
$projectPath = $PSScriptRoot
py -m unittest discover -s "$projectPath/tests/raven" -p test_vns5_contract.py
if ($LASTEXITCODE -ne 0) { throw 'VNS5 contract audit failed.' }
py "$projectPath/scripts/raven/tools/reconcile_gap_statuses.py" --check
if ($LASTEXITCODE -ne 0) { throw 'Backlog gap status audit failed.' }
py "$projectPath/scripts/raven/tools/validate_backlog_dependencies.py"
if ($LASTEXITCODE -ne 0) { throw 'Backlog dependency graph audit failed.' }
py "$projectPath/scripts/raven/tools/validate_active_workstreams.py"
if ($LASTEXITCODE -ne 0) { throw 'Backlog workstreams audit failed.' }
py "$projectPath/scripts/raven/tools/validate_backlog_acceptance.py"
if ($LASTEXITCODE -ne 0) { throw 'P2 reentry/QA matrix audit failed.' }

function Invoke-GodotCheck {
	param([string]$Stage, [string[]]$Arguments, [string]$ExpectedOutput = '')
	$stdoutPath = [System.IO.Path]::GetTempFileName()
	$stderrPath = [System.IO.Path]::GetTempFileName()
	try {
		$process = Start-Process -FilePath $GodotPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow `
			-RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
		$stdout = Get-Content -LiteralPath $stdoutPath -Raw
		$stderr = Get-Content -LiteralPath $stderrPath -Raw
		if ($null -eq $stderr) { $stderr = '' }
		if ($process.ExitCode -ne 0 -or $stderr -match 'SCRIPT ERROR:' -or $stderr.Contains('res://addons/vn_studio/res:') -or $stderr.Contains('Failed loading resource: res://addons/vn_studio/')) {
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
Invoke-GodotCheck 'VN Studio Legacy Viewer synthetic' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_legacy_smoke.gd', '--quit-after', '120') 'Raven VN Studio read-only legacy viewer smoke passed'
Invoke-GodotCheck 'VN Studio draft overlay round-trip' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_drafts_smoke.gd', '--quit-after', '120') 'Raven VN Studio draft overlay round-trip smoke passed'
Invoke-GodotCheck 'VN Studio character catalog' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_catalog_smoke.gd', '--quit-after', '120') 'Raven VN Studio character library smoke passed'
Invoke-GodotCheck 'VN Studio story graph' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_story_graph_smoke.gd', '--quit-after', '120') 'Raven VN Studio story graph smoke passed'
Invoke-GodotCheck 'VN Studio conversion dry-run and export' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_migration_smoke.gd', '--quit-after', '120') 'Raven VN Studio migration dry-run and immutable export smoke passed'
Invoke-GodotCheck 'VN Studio old-save preview and semantic diff' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_save_position_smoke.gd', '--quit-after', '120') 'Raven VN Studio old-save position inspection smoke passed'
Invoke-GodotCheck 'VN Studio semantic replay parity' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_story_semantics_smoke.gd', '--quit-after', '120') 'Raven VN Studio data semantic parity replay smoke passed'
Invoke-GodotCheck 'VN Studio Raven Manor authoring' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_raven_story_smoke.gd', '--quit-after', '120') 'Raven VN Studio local story authoring and safe export smoke passed'
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
	'res://scripts/match3/match3_drag_model.gd',
	'res://scripts/match3/match3_mobile_layout.gd',
	'res://scripts/match3/match3_frame_visuals.gd',
	'res://scripts/match3/match3_board_presenter.gd',
	'res://scripts/match3/match3_screen_shell.gd',
	'res://scripts/raven/raven_match3_theme.gd',
	'res://scripts/raven/raven_menu_copy.gd',
	'res://scripts/raven/raven_settings_dialog.gd',
	'res://scripts/raven/raven_onboarding_dialog.gd',
	'res://scripts/raven/raven_audio_synthesis.gd',
	'res://scripts/raven/raven_audio_runtime.gd',
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
Invoke-GodotCheck 'CODE-07-02 restoration restore/snapshot' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/restoration_restore_smoke.gd', '--quit-after', '120') 'Raven Manor restoration restore/snapshot characterization smoke passed'
Invoke-GodotCheck 'Raven navigation graph smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/manor_navigation_graph_smoke.gd', '--quit-after', '120') 'Raven Manor authored navigation graph smoke passed'
Invoke-GodotCheck 'Prototype Lab smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/prototype_lab_smoke.gd', '--quit-after', '120') 'Raven Manor Prototype Lab smoke passed'
Invoke-GodotCheck 'UPDS engine port parity smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_core_reuse_smoke.gd', '--quit-after', '120') 'Raven Manor UPDS core reuse smoke passed'
Invoke-GodotCheck 'UPDS M3 visual primitives' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_match3_visual_primitives_smoke.gd', '--quit-after', '120') 'Raven Manor UPDS Match-3 visual primitives smoke passed'
Invoke-GodotCheck 'UPDS Match-3 full-screen layout' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/match3_upds_shell_smoke.gd', '--quit-after', '180') 'Raven UPDS-style Match-3 full-screen layout smoke passed'
Invoke-GodotCheck 'UPDS Match3 interactive board' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_match3_interactive_board_smoke.gd', '--quit-after', '120') 'Raven Manor UPDS interactive Match-3 board smoke passed'
Invoke-GodotCheck 'UPDS M3 help, blockers and retry' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_match3_presentation_states_smoke.gd', '--quit-after', '120') 'Raven Manor UPDS Match-3 help, objectives, special/blocker and retry smoke passed'
Invoke-GodotCheck 'UPDS Match3 frame FX / blocker segments' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_match3_frame_fx_smoke.gd', '--quit-after', '120') 'Raven Manor UPDS special-impact and blocker-segment settle smoke passed'
Invoke-GodotCheck 'CODE-02D mobile HUD and safe-area' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/upds_match3_mobile_hud_smoke.gd', '--quit-after', '120') 'Raven Manor CODE-02D mobile HUD layout and safe-area smoke passed'
Invoke-GodotCheck 'Match3 direct QA Content Preview' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/content_preview_match3_qa_smoke.gd', '--quit-after', '120') 'Raven Manor Match-3 QA shortcut and UPDS Content Preview parity smoke passed.'
Invoke-GodotCheck 'Device matrix reachability' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/device_matrix_reachability_smoke.gd', '--quit-after', '240') 'Raven Manor device matrix 320/390/430 reachability smoke passed'
Invoke-GodotCheck 'RM-VS-01 vertical slice smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vertical_slice_smoke.gd', '--quit-after', '120') 'Raven Manor RM-VS-01 smoke passed'
Invoke-GodotCheck 'Main menu settings smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/main_menu_smoke.gd', '--quit-after', '120') 'Raven Manor main menu and Prototype Lab navigation smoke passed'

Invoke-GodotCheck 'Narrative production contract smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/production_narrative_smoke.gd', '--quit-after', '120') 'Raven Manor production narrative contract smoke passed'

Invoke-GodotCheck 'VN background catalog / gallery' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_background_gallery_smoke.gd', '--quit-after', '120') 'Raven VN background registry and 9 textures PASS'
Invoke-GodotCheck 'VN Studio responsive layout' @('--headless', '--editor', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_layout_smoke.gd', '--quit-after', '120') 'Raven VN Studio responsive layout smoke passed'
Invoke-GodotCheck 'VN Studio asset registry' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_asset_registry_smoke.gd', '--quit-after', '120') 'Raven VN Studio asset registry read-only smoke passed'
Invoke-GodotCheck 'VN Studio staged image import safety' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_staged_image_smoke.gd', '--quit-after', '120') 'Raven VN Studio staged image import safety smoke passed'
Invoke-GodotCheck 'VN Studio orientation/templates/undo' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_stage_orientation_smoke.gd', '--quit-after', '180') 'Raven VN Studio VNS5-04A orientation/template/undo smoke passed'
Invoke-GodotCheck 'VN Studio stage-v2 sidecar/props' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_stage_v2_smoke.gd', '--quit-after', '240') 'Raven VN Studio VNS5-04B sidecar/focal/prop/z-order safety smoke passed'
Invoke-GodotCheck 'VN Studio micro-FX timeline' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_stage_fx_smoke.gd', '--quit-after', '240') 'Raven VN Studio VNS5-05A micro-FX timeline safety smoke passed'
Invoke-GodotCheck 'VN Studio VNS5-12 branch-and-FX draft demo' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_branch_demo_smoke.gd', '--quit-after', '240') 'Raven VN Studio three-way branch-and-FX draft-only demo smoke passed'
Invoke-GodotCheck 'VN Studio VNS5-09 full authoring save/reopen' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_full_authoring_e2e_smoke.gd', '--quit-after', '240') 'Raven VN Studio VNS5-09 full authoring round-trip smoke passed'
Invoke-GodotCheck 'VN Studio background-state preview' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_studio_backgrounds_smoke.gd', '--quit-after', '120') 'Raven VN Studio background-state preview smoke passed'
Invoke-GodotCheck 'Approved character art integration' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_character_art_smoke.gd', '--quit-after', '240') 'Raven approved character art smoke passed'
Invoke-GodotCheck 'Layered Hall VN pilot smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/hall_tea_vn_smoke.gd', '--quit-after', '120') 'Raven Manor Hall tea VN pilot smoke passed'
Invoke-GodotCheck 'Live Raven VN gameplay backgrounds' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_runtime_background_smoke.gd', '--quit-after', '240') 'Raven live VN background compositor passed'
Invoke-GodotCheck 'Hall VN runtime UI smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/hall_tea_vn_ui_smoke.gd', '--quit-after', '240') 'Raven Manor Hall VN UI runtime smoke passed'
Invoke-GodotCheck 'Whole season1 map smoke' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/season1_map_smoke.gd', '--quit-after', '120') 'Raven Manor continuous season1 map smoke passed'

Invoke-GodotCheck 'UPDS VN shell layout and input' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_shell_layout_smoke.gd', '--quit-after', '600') 'Raven UPDS VN shell layout and input smoke passed'
Invoke-GodotCheck 'VN game frame safe-area and locale overflow' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_shell_safe_area_smoke.gd', '--quit-after', '240') 'Raven VN game frame safe-area and locale overflow smoke passed'
Invoke-GodotCheck 'Runtime settings persistence and modal' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/runtime_settings_smoke.gd', '--quit-after', '240') 'Raven runtime settings persistence, modal and locale smoke passed'
Invoke-GodotCheck 'Replayable onboarding' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/onboarding_smoke.gd', '--quit-after', '240') 'Raven first-session and replayable onboarding smoke passed'
Invoke-GodotCheck 'Procedural audio runtime' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/audio_runtime_smoke.gd', '--quit-after', '240') 'Raven procedural audio runtime, preference gating and focus smoke passed'

Invoke-GodotCheck 'VN persisted read-only Skip' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_read_skip_smoke.gd', '--quit-after', '600') 'Raven VN persisted read-only Skip smoke passed'
Invoke-GodotCheck 'VN tri-locale save/reload parity' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/vn_locale_save_parity_smoke.gd', '--quit-after', '240') 'Raven tri-locale VN save/reload parity smoke passed'

Invoke-GodotCheck 'Match-3 viewport pointer and modal' @('--headless', '--path', $projectPath, '--script', 'res://tests/raven/match3_viewport_input_smoke.gd', '--quit-after', '240') 'Raven Match-3 viewport pointer and modal smoke passed'

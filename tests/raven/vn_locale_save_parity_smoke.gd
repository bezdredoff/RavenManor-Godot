extends SceneTree
## Tri-locale (RU/BE/EN) Save -> reload -> Continue parity for the playable VN.
## In-memory campaign storage only; language preferences use an isolated file.
## Proves cursor/read-history persistence, localized copy after Continue,
## non-advancing paging/Auto on the restored line and read-only Skip gates.
const Slice = preload("res://scripts/raven/vertical_slice.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")

const SETTINGS_PATH := "user://raven_locale_save_parity_smoke.cfg"
const LOCALES := ["ru", "be", "en"]
const BEAT := "RM-BEAT-00-01"
const NEXT_COPY := {"ru": "Далее ›", "be": "Далей ›", "en": "Next ›"}


func _initialize() -> void:
	call_deferred("_run")


func _spawn(memory: RefCounted, locale: String) -> Control:
	var slice := Slice.new()
	slice.store = Store.new(memory)
	root.add_child(slice)
	await process_frame
	# Vertical slice takes the audio runtime's preferences; swap in an isolated
	# file so the player's real language setting is never touched.
	slice.preferences = Copy.new(SETTINGS_PATH)
	slice._switch_locale(Copy.SUPPORTED_LOCALES.find(locale))
	await process_frame
	return slice


func _history_texts(view: Control) -> Array:
	var texts: Array = []
	for entry: Dictionary in view._history_lines:
		texts.append(str(entry.get("text", "")))
	return texts


func _run() -> void:
	var shared_ids: Array = []
	var paged_locales := 0
	for locale: String in LOCALES:
		var memory := Memory.new()
		var live := await _spawn(memory, locale)
		assert(live.preferences.locale == locale, locale + ": locale not applied")
		assert(live.step.kind == "vn", locale + ": first step is not VN")
		assert(str(live.vn_player.scene.get("beatId", "")) == BEAT, locale + ": unexpected beat")
		var ids: Array = live.vn_player.scene.get("lineIds", [])
		assert(ids.size() >= 4, locale + ": line IDs missing")
		if shared_ids.is_empty():
			shared_ids = ids.duplicate()
		# Stable RM line IDs are locale-independent by contract.
		assert(ids == shared_ids, locale + ": line IDs changed with locale")
		assert(live.state.vnReadLines.is_empty(), locale + ": fresh campaign already has read history")

		# 1) Advance several story lines in this locale.
		live._advance_vn()
		assert(live.vn_player.line_index == 1, locale + ": first advance failed")
		live._advance_vn()
		assert(live.vn_player.line_index == 2, locale + ": second advance failed")
		assert(live.state.vnReadLines == [ids[0], ids[1]], locale + ": read history not recorded")
		assert(int(live.state.vnCursor.get("lineIndex", -1)) == 2, locale + ": cursor not saved")
		assert(str(live.state.vnCursor.get("beatId", "")) == BEAT, locale + ": cursor beat not saved")
		assert(live.vn_view._full_text == Copy.line_text(str(ids[2]), locale), locale + ": live copy not localized")

		# 2) Explicit Save, then Continue from a rebuilt scene.
		live._save()
		var stored := Store.new(memory).load_campaign()
		assert(int(stored.vnCursor.get("lineIndex", -1)) == 2, locale + ": Save lost the cursor")
		assert(stored.vnReadLines == [ids[0], ids[1]], locale + ": Save lost read history")
		live.queue_free()
		await process_frame

		var resumed := await _spawn(memory, locale)
		assert(resumed.step.kind == "vn", locale + ": Continue left the VN step")
		assert(resumed.vn_player.line_index == 2, locale + ": Continue lost the line")
		assert(int(resumed.state.vnCursor.get("lineIndex", -1)) == 2, locale + ": Continue lost the cursor")
		assert(resumed.state.vnReadLines == [ids[0], ids[1]], locale + ": Continue lost read history")

		# Localized copy and history must match the selected locale.
		assert(resumed.vn_view._display_locale == locale, locale + ": view locale mismatch")
		assert(resumed.vn_view._full_text == Copy.line_text(str(ids[2]), locale), locale + ": restored copy mismatch")
		assert(resumed.vn_view.chapter.text == Copy.scene_title(BEAT, locale), locale + ": scene title mismatch")
		assert(resumed.vn_view.nameplate.text == Copy.speaker_name(
			str(Copy.line_by_id(str(ids[2])).get("speakerId", "")), locale).to_upper(), locale + ": speaker mismatch")
		assert(resumed.vn_view.next_button.text == NEXT_COPY[locale], locale + ": Next label mismatch")
		var history := _history_texts(resumed.vn_view)
		assert(history.size() == 2, locale + ": persisted read history missing")
		for i in history.size():
			assert(history[i] == Copy.line_text(str(ids[i]), locale), locale + ": history copy mismatch")

		# 3) Paging/Auto on the restored line never advance the cursor.
		assert(resumed.vn_view._page_index == 0, locale + ": Continue resumed on a later page")
		var pages: int = resumed.vn_view._pages.size()
		assert(pages >= 1, locale + ": dialogue was not paginated")
		while resumed.vn_view._page_index < pages - 1:
			resumed.vn_view._next()
		assert(resumed.vn_view._page_index == pages - 1, locale + ": paging did not reach the last page")
		assert(resumed.vn_player.line_index == 2, locale + ": paging advanced the restored line")
		assert(int(resumed.state.vnCursor.lineIndex) == 2, locale + ": paging moved the saved cursor")
		assert(resumed.state.vnReadLines == [ids[0], ids[1]], locale + ": paging marked an unread line")
		if pages > 1:
			paged_locales += 1
		assert(not resumed.vn_view._auto_mode, locale + ": Auto resumed enabled")
		assert(resumed.vn_view._auto_timer.is_stopped(), locale + ": Auto timer running after Continue")
		resumed.vn_view._on_auto_timeout()
		assert(resumed.vn_player.line_index == 2, locale + ": Auto advanced the restored line")
		resumed.queue_free()
		await process_frame

		# 4) Skip stops on unread text in every locale: two completed lines are
		# persisted, cursor rewound to line 0, so Skip must stop exactly at line 2.
		var fixture := Store.new(memory).load_campaign()
		fixture.vnReadLines = [ids[0], ids[1]]
		fixture.vnCursor = {"beatId": BEAT, "lineIndex": 0}
		assert(Store.new(memory).save_campaign(fixture), locale + ": could not stage reread fixture")
		var reader := await _spawn(memory, locale)
		assert(reader.vn_player.line_index == 0, locale + ": fixture cursor not honoured")
		assert(not reader.vn_view.skip_button.disabled, locale + ": Skip disabled with reread lines ahead")
		reader.vn_view._skip_read_lines()
		assert(reader.vn_player.line_index == 2, locale + ": Skip did not stop at the first unread line")
		assert(reader.state.vnReadLines == [ids[0], ids[1]], locale + ": Skip marked unread text as read")
		assert(not reader.state.vnReadLines.has(str(ids[2])), locale + ": unread line became read")
		assert(reader.vn_view._full_text == Copy.line_text(str(ids[2]), locale), locale + ": Skip landed on wrong copy")
		assert(reader.vn_view.skip_button.disabled, locale + ": Skip still enabled on unread text")
		assert(Store.new(memory).load_campaign().vnCursor.get("lineIndex", -1) == 2, locale + ": Skip cursor not saved")
		reader.vn_view._skip_read_lines()
		assert(reader.vn_player.line_index == 2, locale + ": repeated Skip crossed unread text")
		assert(reader.step.kind == "vn", locale + ": Skip completed the scene")
		assert(reader.vn_player.line_index < ids.size() - 1, locale + ": Skip reached the last line")
		assert(not reader.state.storyBeatsSeen.has(BEAT), locale + ": Skip advanced the story beat")
		reader.queue_free()
		await process_frame

	# The paging branch must be exercised, not trivially skipped, in the suite.
	assert(paged_locales >= 1, "No locale produced a multi-page line; paging is unverified")
	# Let the procedural VN advance effect finish before shutdown.
	await create_timer(0.5).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	print("Raven tri-locale VN save/reload parity smoke passed")
	quit()

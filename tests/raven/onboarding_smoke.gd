extends SceneTree

const Onboarding = preload("res://scripts/raven/raven_onboarding_dialog.gd")
const Slice = preload("res://scripts/raven/vertical_slice.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(320, 568)
	var guide := Onboarding.new()
	guide.setup("ru")
	root.add_child(guide)
	await process_frame
	assert(guide.find_child("RavenOnboardingTopic0", true, false) != null)
	assert(guide.find_child("RavenOnboardingTopic4", true, false) != null)
	assert((guide.find_child("RavenOnboardingBody3", true, false) as Label).text.contains("Подсказка"))
	guide.set_locale("en")
	assert(guide.title == "How to Play")
	assert((guide.find_child("RavenOnboardingBody4", true, false) as Label).text.contains("Continue"))
	var close_state := {"closed": false}
	guide.closed.connect(func() -> void: close_state.closed = true)
	guide.open_centered()
	await process_frame
	assert(guide.visible and guide.size.x <= root.size.x and guide.size.y <= root.size.y)
	(guide.find_child("RavenOnboardingClose", true, false) as Button).pressed.emit()
	assert(close_state.closed and not guide.visible, "Guide close must work and be observable")
	guide.queue_free()
	await process_frame

	# A replay during gameplay blocks the active VN input but never writes campaign state.
	var slice := Slice.new()
	slice.store = Store.new(MemoryStorage.new())
	root.add_child(slice)
	await process_frame
	await process_frame
	assert(slice.step.kind == "vn")
	var revision_before: int = slice.state.revision
	slice._open_onboarding()
	await process_frame
	assert(slice.onboarding_dialog.visible)
	assert(slice.vn_view._interaction_blocked, "Guide must block VN input")
	assert(slice.state.revision == revision_before, "Opening help must not advance campaign state")
	slice.onboarding_dialog._close_guide()
	await process_frame
	assert(not slice.vn_view._interaction_blocked, "Closing guide must restore VN input")
	assert(slice.state.revision == revision_before)
	slice.queue_free()
	await process_frame
	print("Raven first-session and replayable onboarding smoke passed")
	quit()

@tool
extends EditorPlugin

const StudioView = preload("res://addons/vn_studio/editor/studio_view.gd")

var _view: Control


func _enter_tree() -> void:
	_view = StudioView.new()
	_view.name = "VN Studio"
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(_view)
	_view.hide()


func _exit_tree() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "VN Studio"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Animation", "EditorIcons")


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_view):
		_view.visible = visible

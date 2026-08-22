@tool
extends EditorPlugin

const Dock := preload("res://editor/map_authoring/presentation/map_workbench_dock.gd")

var _dock: Control

func _enter_tree() -> void:
	_dock = Dock.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	scene_changed.connect(_on_scene_changed)

func _exit_tree() -> void:
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if _dock == null:
		return
	remove_control_from_docks(_dock)
	_dock.free()
	_dock = null

func _on_scene_changed(_scene_root: Node) -> void:
	if _dock != null:
		_dock.call_deferred("sync_from_edited_scene")

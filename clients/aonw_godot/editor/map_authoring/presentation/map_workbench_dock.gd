@tool
extends "res://editor/map_authoring/presentation/map_workbench_view.gd"

var _catalog: AonwMapSourceCatalog
var _scene_writer: AonwTerrainAuthoringSceneWriter
var _generator: AonwGenerateTerrainAuthoringMap
var _sources: Array[AonwMapSource] = []

func configure(
	catalog: AonwMapSourceCatalog,
	generator: AonwGenerateTerrainAuthoringMap,
	scene_writer: AonwTerrainAuthoringSceneWriter,
) -> void:
	_catalog = catalog
	_generator = generator
	_scene_writer = scene_writer

func _ready() -> void:
	assert(_catalog != null, "Map source catalog is required")
	assert(_generator != null, "Terrain authoring generator is required")
	assert(_scene_writer != null, "Terrain authoring scene writer is required")
	_build_interface()
	_connect_interface()
	_refresh_sources()

func _connect_interface() -> void:
	_refresh_button.pressed.connect(_refresh_sources)
	_generate_button.pressed.connect(_generate_selected_map)
	_open_button.pressed.connect(_open_selected_scene)
	_reference_toggle.toggled.connect(_set_reference_visible)
	_reference_opacity.value_changed.connect(_set_reference_opacity)
	_grid_toggle.toggled.connect(_set_grid_visible)
	_grid_opacity.value_changed.connect(_set_grid_opacity)
	_constraints_toggle.toggled.connect(_set_constraints_visible)
	_city_marker_toggle.toggled.connect(_set_city_marker_visible)
	_city_col.value_changed.connect(_set_city_marker_coordinate)
	_city_row.value_changed.connect(_set_city_marker_coordinate)
	_reload_base_button.pressed.connect(_reload_generated_base)
	_save_draft_button.pressed.connect(_save_draft)
	_publish_button.pressed.connect(_publish)

func _refresh_sources() -> void:
	_sources = _catalog.discover()
	_map_picker.clear()
	for source in _sources:
		_map_picker.add_item(source.display_name())
	if _sources.is_empty():
		_status.text = "No maps found."
		_set_source_actions_enabled(false)
		return
	_set_source_actions_enabled(true)
	_status.text = "Available maps: %d. Terrain profiles are required." % _sources.size()

func _generate_selected_map() -> void:
	var source := _selected_source()
	if source == null:
		return
	_set_busy(true)
	_status.text = "Preparing Terrain3D authoring for %s…" % source.map_id
	await get_tree().process_frame
	var result := _generator.execute(source)
	_set_busy(false)
	if not result["ok"]:
		_show_error(result["message"])
		return
	EditorInterface.get_resource_filesystem().scan()
	_status.text = (
		"Terrain3D authoring scene created."
		if result["scene_created"]
		else "Existing Terrain3D scene kept; compiled inputs refreshed."
	)
	EditorInterface.open_scene_from_path(result["scene_path"])

func _open_selected_scene() -> void:
	var source := _selected_source()
	if source == null:
		return
	var scene_path := _scene_writer.scene_path_for(source.map_id)
	if not ResourceLoader.exists(scene_path):
		_status.text = "Create the Terrain3D authoring scene first."
		return
	EditorInterface.open_scene_from_path(scene_path)

func _set_reference_visible(value: bool) -> void:
	_commit_change(
		"Toggle terrain reference",
		&"set_reference_visible",
		value,
		_current_value(&"reference_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_reference_opacity(value: float) -> void:
	_update_opacity_labels()
	_commit_change(
		"Change terrain reference opacity",
		&"set_reference_opacity",
		value,
		_current_value(&"reference_opacity"),
		UndoRedo.MERGE_ENDS,
	)

func _set_grid_visible(value: bool) -> void:
	_commit_change(
		"Toggle terrain hex grid",
		&"set_grid_visible",
		value,
		_current_value(&"grid_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_grid_opacity(value: float) -> void:
	_update_opacity_labels()
	_commit_change(
		"Change terrain grid opacity",
		&"set_grid_opacity",
		value,
		_current_value(&"grid_opacity"),
		UndoRedo.MERGE_ENDS,
	)

func _set_constraints_visible(value: bool) -> void:
	_commit_change(
		"Toggle terrain constraint envelopes",
		&"set_constraints_visible",
		value,
		_current_value(&"constraints_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_city_marker_visible(value: bool) -> void:
	_commit_change(
		"Toggle city-core marker",
		&"set_city_marker_visible",
		value,
		_current_value(&"city_marker_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_city_marker_coordinate(_value: float) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var coordinate := Vector2i(roundi(_city_col.value), roundi(_city_row.value))
	if coordinate == surface.city_marker_coordinate:
		return
	_commit_change(
		"Move city-core marker",
		&"set_city_marker_coordinate",
		coordinate,
		surface.city_marker_coordinate,
		UndoRedo.MERGE_ENDS,
	)

func _reload_generated_base() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var result := surface.refresh_generated_artifact()
	if not result["ok"]:
		_show_error(result["message"])
		return
	_status.text = "Compiled base and constraints reloaded; manual final terrain preserved."

func _save_draft() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var result := surface.save_draft()
	if not result["ok"]:
		_show_error(result["message"])
		return
	var scene_error := EditorInterface.save_scene()
	_status.text = (
		"Terrain3D draft and scene saved."
		if scene_error == OK
		else "Terrain3D draft saved, but the scene could not be saved."
	)

func _publish() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var scene_error := EditorInterface.save_scene()
	if scene_error != OK:
		_show_error("scene could not be saved; terrain was not published")
		return
	var result := surface.publish()
	if not result["ok"]:
		_show_error(result["message"])
		return
	_status.text = "Terrain3D final validated and published at revision %d." % surface.terrain_revision

func sync_from_edited_scene() -> void:
	var surface := _current_surface()
	var enabled := surface != null
	for control in [
		_reference_toggle, _reference_opacity, _grid_toggle, _grid_opacity,
		_constraints_toggle, _city_marker_toggle, _city_col, _city_row,
		_reload_base_button, _save_draft_button, _publish_button,
	]:
		if control is BaseButton:
			control.disabled = not enabled
		else:
			control.editable = enabled
	if surface == null:
		return
	_reference_toggle.set_pressed_no_signal(surface.reference_visible)
	_reference_opacity.set_value_no_signal(surface.reference_opacity)
	_grid_toggle.set_pressed_no_signal(surface.grid_visible)
	_grid_opacity.set_value_no_signal(surface.grid_opacity)
	_constraints_toggle.set_pressed_no_signal(surface.constraints_visible)
	_city_marker_toggle.set_pressed_no_signal(surface.city_marker_visible)
	var artifact := surface.artifact()
	if artifact != null:
		_city_col.max_value = maxf(0.0, float(artifact.cols - 1))
		_city_row.max_value = maxf(0.0, float(artifact.rows - 1))
	_city_col.set_value_no_signal(surface.city_marker_coordinate.x)
	_city_row.set_value_no_signal(surface.city_marker_coordinate.y)
	_update_opacity_labels()

func _commit_change(
	action_name: String,
	method: StringName,
	value: Variant,
	previous_value: Variant,
	merge_mode: UndoRedo.MergeMode,
) -> void:
	var surface := _current_surface()
	if surface == null or previous_value == null or value == previous_value:
		return
	var history := EditorInterface.get_editor_undo_redo()
	history.create_action(action_name, merge_mode, surface)
	history.add_do_method(surface, method, value)
	history.add_undo_method(surface, method, previous_value)
	history.commit_action()

func _current_value(property: StringName) -> Variant:
	var surface := _current_surface()
	return surface.get(property) if surface != null else null

func _current_surface() -> AonwTerrainAuthoringSurface:
	var root := EditorInterface.get_edited_scene_root()
	if root is AonwTerrainAuthoringSurface:
		return root
	if root == null:
		return null
	return root.find_child("TerrainAuthoring", true, false) as AonwTerrainAuthoringSurface

func _selected_source() -> AonwMapSource:
	var index := _map_picker.selected
	if index < 0 or index >= _sources.size():
		_status.text = "Select a map."
		return null
	return _sources[index]

func _set_busy(busy: bool) -> void:
	_generate_button.disabled = busy
	_open_button.disabled = busy
	_map_picker.disabled = busy

func _set_source_actions_enabled(enabled: bool) -> void:
	_generate_button.disabled = not enabled
	_open_button.disabled = not enabled
	_map_picker.disabled = not enabled

func _show_error(message: String) -> void:
	_status.text = "Error: %s" % message
	push_error("AoNW Terrain Workbench: %s" % message)

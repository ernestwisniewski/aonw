@tool
extends "res://addons/aonw_map_workbench/presentation/map_workbench_view.gd"

const MapAssetCatalog := preload("res://infrastructure/map/map_asset_catalog.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")
const OpenMap := preload("res://application/map/open_map.gd")
const GenerateGodotMap := preload("res://application/map/generate_godot_map.gd")
const GodotMapSceneRepository := preload("res://infrastructure/map/godot_map_scene_repository.gd")
const Terrain3DAdapter := preload(
	"res://presentation/map/terrain3d/terrain3d_runtime_adapter.gd"
)

var _catalog := MapAssetCatalog.new()
var _map_reader := JsonMapRepository.new()
var _generator := GenerateGodotMap.new(
	OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new()),
	GodotMapSceneRepository.new(),
)
var _scene_repository := GodotMapSceneRepository.new()
var _sources: Array[AonwMapSource] = []

func _ready() -> void:
	_build_interface()
	_connect_interface()
	_update_terrain3d_availability()
	_refresh_sources()

func _connect_interface() -> void:
	_refresh_button.pressed.connect(_refresh_sources)
	_generate_button.pressed.connect(_generate_selected_map)
	_open_button.pressed.connect(_open_selected_scene)
	_terrain_backend.item_selected.connect(_on_terrain_backend_selected)
	_terrain_samples.value_changed.connect(_queue_geometry_update)
	_terrain_region_size.item_selected.connect(_queue_geometry_update)
	_reference_toggle.toggled.connect(_set_reference_visible)
	_reference_opacity.value_changed.connect(_set_reference_opacity)
	_height_step.value_changed.connect(_queue_geometry_update)
	_grid_toggle.toggled.connect(_set_grid_visible)
	_grid_opacity.value_changed.connect(_set_grid_opacity)
	_grid_width.value_changed.connect(_queue_geometry_update)
	_geometry_update_timer.timeout.connect(_apply_geometry_settings)
	_save_button.pressed.connect(_save_current_scene)

func _refresh_sources() -> void:
	_sources = _catalog.discover()
	_map_picker.clear()
	for source in _sources:
		_map_picker.add_item(source.display_name())
	if _sources.is_empty():
		_status.text = "No maps found in assets, content, or res://assets/maps."
		_generate_button.disabled = true
		_open_button.disabled = true
		return
	_generate_button.disabled = false
	_open_button.disabled = false
	_status.text = "Available maps: %d" % _sources.size()

func _generate_selected_map() -> void:
	var source := _selected_source()
	if source == null:
		return
	var target_scene := GodotMapSceneRepository.SCENE_ROOT.path_join(
		"%s.tscn" % source.map_id
	)
	if target_scene in EditorInterface.get_unsaved_scenes():
		_status.text = "Save the open %s scene before regenerating it." % source.map_id
		return
	_set_busy(true)
	_status.text = "Building %s…" % source.map_id
	await get_tree().process_frame
	var result := _generator.execute(source, {
		"height_step": _height_step.value,
		"terrain_backend": selected_terrain_backend(),
		"terrain_samples_per_radius": roundi(_terrain_samples.value),
		"terrain3d_region_size": selected_terrain_region_size(),
		"reference_visible": _reference_toggle.button_pressed,
		"reference_opacity": _reference_opacity.value,
		"grid_visible": _grid_toggle.button_pressed,
		"grid_opacity": _grid_opacity.value,
		"grid_width": _grid_width.value,
	})
	_set_busy(false)
	if not result["ok"]:
		_status.text = "Error: %s" % result["message"]
		push_error("AoNW Map Workbench: %s" % result["message"])
		return
	EditorInterface.get_resource_filesystem().scan()
	_status.text = _success_message(source, result)
	EditorInterface.open_scene_from_path(result["scene_path"])

func _open_selected_scene() -> void:
	var source := _selected_source()
	if source == null:
		return
	var scene_path := GodotMapSceneRepository.SCENE_ROOT.path_join(
		"%s.tscn" % source.map_id
	)
	if not ResourceLoader.exists(scene_path):
		_status.text = "Generate the 3D map first."
		return
	EditorInterface.open_scene_from_path(scene_path)

func _on_terrain_backend_selected(_index: int) -> void:
	_update_terrain_control_state()
	_update_terrain3d_availability()
	_queue_geometry_update()

func _set_reference_visible(value: bool) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	if surface.render_settings.reference_visible == value:
		return
	_commit_surface_change(
		"Toggle reference texture",
		surface,
		&"set_reference_visible",
		value,
		surface.render_settings.reference_visible,
		UndoRedo.MERGE_DISABLE,
	)

func _set_reference_opacity(value: float) -> void:
	_update_opacity_labels()
	var surface := _current_surface()
	if surface == null:
		return
	if is_equal_approx(surface.render_settings.reference_opacity, value):
		return
	_commit_surface_change(
		"Change reference opacity",
		surface,
		&"set_reference_opacity",
		value,
		surface.render_settings.reference_opacity,
		UndoRedo.MERGE_ENDS,
	)

func _queue_geometry_update(_value: Variant = null) -> void:
	_geometry_update_timer.start()

func _apply_geometry_settings() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	if not surface.has_editing_context():
		var context_result := _restore_surface_editing_context(surface)
		if not context_result["ok"]:
			_status.text = "Error: %s" % context_result["message"]
			return
	var next_height := float(_height_step.value)
	var next_grid_width := float(_grid_width.value)
	var next_backend := selected_terrain_backend()
	var next_samples := roundi(_terrain_samples.value)
	var next_region_size := selected_terrain_region_size()
	if (
		is_equal_approx(surface.render_settings.height_step, next_height)
		and is_equal_approx(surface.render_settings.grid_width, next_grid_width)
		and surface.render_settings.terrain_backend == next_backend
		and surface.render_settings.terrain_samples_per_radius == next_samples
		and surface.render_settings.terrain3d_region_size == next_region_size
	):
		return
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action("Change map terrain", UndoRedo.MERGE_DISABLE, surface)
	undo_redo.add_do_method(
		surface,
		"set_render_configuration",
		next_height,
		next_grid_width,
		next_backend,
		next_samples,
		next_region_size,
	)
	undo_redo.add_undo_method(
		surface,
		"set_render_configuration",
		surface.render_settings.height_step,
		surface.render_settings.grid_width,
		surface.render_settings.terrain_backend,
		surface.render_settings.terrain_samples_per_radius,
		surface.render_settings.terrain3d_region_size,
	)
	undo_redo.commit_action()
	var validation := surface.validate_backend()
	if not validation["ok"]:
		_status.text = "Terrain backend warning: %s" % validation["message"]

func _set_grid_visible(value: bool) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	if surface.render_settings.grid_visible == value:
		return
	_commit_surface_change(
		"Toggle hex outlines",
		surface,
		&"set_grid_visible",
		value,
		surface.render_settings.grid_visible,
		UndoRedo.MERGE_DISABLE,
	)

func _set_grid_opacity(value: float) -> void:
	_update_opacity_labels()
	var surface := _current_surface()
	if surface == null:
		return
	if is_equal_approx(surface.render_settings.grid_opacity, value):
		return
	_commit_surface_change(
		"Change outline opacity",
		surface,
		&"set_grid_opacity",
		value,
		surface.render_settings.grid_opacity,
		UndoRedo.MERGE_ENDS,
	)

func _save_current_scene() -> void:
	var surface := _current_surface()
	if surface == null:
		_status.text = "The current scene does not contain an AoNW map."
		return
	if not surface.has_editing_context():
		var context_result := _restore_surface_editing_context(surface)
		if not context_result["ok"]:
			_status.text = "Error: %s" % context_result["message"]
			return
	var persist_result := _scene_repository.persist_surface_geometry(surface)
	if not persist_result["ok"]:
		_status.text = "Error: %s" % persist_result["message"]
		return
	var error := EditorInterface.save_scene()
	if error == OK:
		var publish_result := _scene_repository.publish_surface_geometry(surface)
		if not publish_result["ok"]:
			_status.text = (
				"Scene saved, but the map manifest could not be published: %s"
				% publish_result["message"]
			)
			return
	_status.text = (
		"Scene and geometry saved."
		if error == OK
		else "Failed to save the scene."
	)

func _selected_source() -> AonwMapSource:
	var index := _map_picker.selected
	if index < 0 or index >= _sources.size():
		_status.text = "Select a map."
		return null
	return _sources[index]

func _current_surface() -> AonwMapSurface:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root is AonwMapSurface:
		return scene_root
	if scene_root == null:
		return null
	return scene_root.find_child("AonwMap3D", true, false) as AonwMapSurface

func _commit_surface_change(
	action_name: String,
	surface: AonwMapSurface,
	method: StringName,
	value: Variant,
	previous_value: Variant,
	merge_mode: UndoRedo.MergeMode,
) -> void:
	var undo_redo := EditorInterface.get_editor_undo_redo()
	undo_redo.create_action(action_name, merge_mode, surface)
	undo_redo.add_do_method(surface, method, value)
	undo_redo.add_undo_method(surface, method, previous_value)
	undo_redo.commit_action()

func sync_from_edited_scene() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	_select_option_by_id(_terrain_backend, surface.render_settings.terrain_backend)
	_terrain_samples.set_value_no_signal(
		float(surface.render_settings.terrain_samples_per_radius)
	)
	_select_option_by_id(
		_terrain_region_size,
		surface.render_settings.terrain3d_region_size,
	)
	_reference_toggle.set_pressed_no_signal(surface.render_settings.reference_visible)
	_reference_opacity.set_value_no_signal(surface.render_settings.reference_opacity)
	_height_step.set_value_no_signal(surface.render_settings.height_step)
	_grid_toggle.set_pressed_no_signal(surface.render_settings.grid_visible)
	_grid_opacity.set_value_no_signal(surface.render_settings.grid_opacity)
	_grid_width.set_value_no_signal(surface.render_settings.grid_width)
	_update_opacity_labels()
	_update_terrain_control_state()
	_update_terrain3d_availability()

func _restore_surface_editing_context(surface: AonwMapSurface) -> Dictionary:
	if surface.source_map_id.is_empty() or surface.source_map_path.is_empty():
		return {"ok": false, "message": "scene does not contain a map source"}
	var source := AonwMapSource.new(
		surface.source_map_id,
		surface.source_map_path,
		"",
		"generated",
	)
	var map_result: Dictionary = _map_reader.load_map(source)
	if not map_result["ok"]:
		return map_result
	if not surface.restore_editing_context(map_result["document"]):
		return {"ok": false, "message": "persisted map textures are missing"}
	return {"ok": true}

func _set_busy(busy: bool) -> void:
	_generate_button.disabled = busy
	_open_button.disabled = busy
	_map_picker.disabled = busy
	_terrain_backend.disabled = busy
	_terrain_samples.editable = not busy and (
		selected_terrain_backend() == RenderSettings.TerrainBackend.TERRAIN_3D
	)
	_terrain_region_size.disabled = busy or (
		selected_terrain_backend() != RenderSettings.TerrainBackend.TERRAIN_3D
	)

func _success_message(source: AonwMapSource, result: Dictionary) -> String:
	var message := "%s was saved as a Godot 3D scene using %s." % [
		source.map_id,
		result.get("terrain_backend", "legacyMesh"),
	]
	if not result["missing_tiles"].is_empty():
		message += " Missing textures: %d." % result["missing_tiles"].size()
	if not result["invalid_tiles"].is_empty():
		message += " Invalid textures: %d." % result["invalid_tiles"].size()
	return message

func _update_terrain3d_availability() -> void:
	set_terrain_backend_status(Terrain3DAdapter.availability_message())

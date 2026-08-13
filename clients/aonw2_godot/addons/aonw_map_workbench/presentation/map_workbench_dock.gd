@tool
extends VBoxContainer

const MapAssetCatalog := preload("res://infrastructure/map/map_asset_catalog.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")
const OpenMap := preload("res://application/map/open_map.gd")
const GenerateGodotMap := preload("res://application/map/generate_godot_map.gd")
const GodotMapSceneRepository := preload("res://infrastructure/map/godot_map_scene_repository.gd")

var _catalog := MapAssetCatalog.new()
var _map_reader := JsonMapRepository.new()
var _generator := GenerateGodotMap.new(
	OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new()),
	GodotMapSceneRepository.new(),
)
var _sources: Array[AonwMapSource] = []
var _map_picker := OptionButton.new()
var _generate_button := Button.new()
var _open_button := Button.new()
var _status := Label.new()
var _reference_toggle := CheckButton.new()
var _reference_opacity := HSlider.new()
var _height_step := HSlider.new()
var _grid_toggle := CheckButton.new()
var _grid_opacity := HSlider.new()

func _ready() -> void:
	name = "AoNW Map"
	custom_minimum_size = Vector2(280.0, 0.0)
	_build_interface()
	_refresh_sources()

func _build_interface() -> void:
	var title := Label.new()
	title.text = "AoNW Map Workbench"
	title.add_theme_font_size_override("font_size", 17)
	add_child(title)

	var description := Label.new()
	description.text = "Mapa AoNW → samodzielna scena Godot 3D"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	add_child(HSeparator.new())

	add_child(_section_label("Mapa źródłowa"))
	add_child(_map_picker)
	var source_actions := HBoxContainer.new()
	var refresh_button := Button.new()
	refresh_button.text = "Odśwież"
	_generate_button.text = "Generuj / aktualizuj 3D"
	_generate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_actions.add_child(refresh_button)
	source_actions.add_child(_generate_button)
	add_child(source_actions)

	_open_button.text = "Otwórz zapisaną scenę"
	add_child(_open_button)
	add_child(HSeparator.new())

	add_child(_section_label("Teren"))
	_height_step.min_value = 0.0
	_height_step.max_value = 1.0
	_height_step.step = 0.01
	_height_step.value = 0.16
	add_child(_control_with_label("Wysokość heksa", _height_step))

	add_child(_section_label("Oryginalna tekstura"))
	_reference_toggle.text = "Widoczna"
	_reference_toggle.button_pressed = true
	add_child(_reference_toggle)
	_reference_opacity.min_value = 0.0
	_reference_opacity.max_value = 1.0
	_reference_opacity.step = 0.01
	_reference_opacity.value = 1.0
	add_child(_control_with_label("Przezroczystość", _reference_opacity))

	add_child(_section_label("Siatka heksów"))
	_grid_toggle.text = "Widoczna"
	_grid_toggle.button_pressed = true
	add_child(_grid_toggle)
	_grid_opacity.min_value = 0.0
	_grid_opacity.max_value = 1.0
	_grid_opacity.step = 0.01
	_grid_opacity.value = 0.72
	add_child(_control_with_label("Krycie siatki", _grid_opacity))

	var save_button := Button.new()
	save_button.text = "Zapisz bieżącą scenę"
	add_child(save_button)
	add_child(HSeparator.new())
	_status.text = "Wybierz mapę z assets."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)

	refresh_button.pressed.connect(_refresh_sources)
	_generate_button.pressed.connect(_generate_selected_map)
	_open_button.pressed.connect(_open_selected_scene)
	_reference_toggle.toggled.connect(_set_reference_visible)
	_reference_opacity.value_changed.connect(_set_reference_opacity)
	_height_step.value_changed.connect(_set_height_step)
	_grid_toggle.toggled.connect(_set_grid_visible)
	_grid_opacity.value_changed.connect(_set_grid_opacity)
	save_button.pressed.connect(_save_current_scene)

func _refresh_sources() -> void:
	_sources = _catalog.discover()
	_map_picker.clear()
	for source in _sources:
		_map_picker.add_item(source.display_name())
	if _sources.is_empty():
		_status.text = "Nie znaleziono map w assets, content ani res://assets/maps."
		_generate_button.disabled = true
		_open_button.disabled = true
		return
	_generate_button.disabled = false
	_open_button.disabled = false
	_status.text = "Dostępne mapy: %d" % _sources.size()

func _generate_selected_map() -> void:
	var source := _selected_source()
	if source == null:
		return
	_set_busy(true)
	_status.text = "Budowanie %s…" % source.map_id
	await get_tree().process_frame
	var result := _generator.execute(source, {
		"height_step": _height_step.value,
		"reference_visible": _reference_toggle.button_pressed,
		"reference_opacity": _reference_opacity.value,
		"grid_visible": _grid_toggle.button_pressed,
		"grid_opacity": _grid_opacity.value,
	})
	_set_busy(false)
	if not result["ok"]:
		_status.text = "Błąd: %s" % result["message"]
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
		_status.text = "Najpierw wygeneruj mapę 3D."
		return
	EditorInterface.open_scene_from_path(scene_path)

func _set_reference_visible(value: bool) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	surface.set_reference_visible(value)
	_mark_scene_changed()

func _set_reference_opacity(value: float) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	surface.set_reference_opacity(value)
	_mark_scene_changed()

func _set_height_step(value: float) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	if not surface.has_editing_context():
		var context_result := _restore_surface_editing_context(surface)
		if not context_result["ok"]:
			_status.text = "Błąd: %s" % context_result["message"]
			return
	surface.set_height_step(value)
	_mark_scene_changed()

func _set_grid_visible(value: bool) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	surface.set_grid_visible(value)
	_mark_scene_changed()

func _set_grid_opacity(value: float) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	surface.set_grid_opacity(value)
	_mark_scene_changed()

func _save_current_scene() -> void:
	var error := EditorInterface.save_scene()
	_status.text = "Scena zapisana." if error == OK else "Nie udało się zapisać sceny."

func _selected_source() -> AonwMapSource:
	var index := _map_picker.selected
	if index < 0 or index >= _sources.size():
		_status.text = "Wybierz mapę."
		return null
	return _sources[index]

func _current_surface() -> AonwMapSurface:
	var scene_root := EditorInterface.get_edited_scene_root()
	if scene_root is AonwMapSurface:
		return scene_root
	if scene_root == null:
		return null
	return scene_root.find_child("AonwMap3D", true, false) as AonwMapSurface

func _mark_scene_changed() -> void:
	EditorInterface.mark_scene_as_unsaved()

func _restore_surface_editing_context(surface: AonwMapSurface) -> Dictionary:
	if surface.source_map_id.is_empty() or surface.source_map_path.is_empty():
		return {"ok": false, "message": "scena nie zawiera źródła mapy"}
	var format := (
		AonwMapSource.Format.LEGACY
		if surface.source_is_legacy
		else AonwMapSource.Format.VERSIONED
	)
	var source := AonwMapSource.new(
		surface.source_map_id,
		surface.source_map_path,
		"",
		format,
		"generated",
	)
	var map_result: Dictionary = _map_reader.load_map(source)
	if not map_result["ok"]:
		return map_result
	var asset_directory := GodotMapSceneRepository.ASSET_ROOT.path_join(surface.source_map_id)
	var terrain_texture := ResourceLoader.load(
		asset_directory.path_join("terrain_texture.res"),
		"Texture2D",
	) as Texture2D
	var reference_texture := ResourceLoader.load(
		asset_directory.path_join("reference_texture.res"),
		"Texture2D",
	) as Texture2D
	if terrain_texture == null or reference_texture == null:
		return {"ok": false, "message": "brak wygenerowanych tekstur mapy"}
	surface.present(map_result["document"], terrain_texture, reference_texture)
	return {"ok": true}

func _set_busy(busy: bool) -> void:
	_generate_button.disabled = busy
	_open_button.disabled = busy
	_map_picker.disabled = busy

func _success_message(source: AonwMapSource, result: Dictionary) -> String:
	var message := "%s zapisano jako scena Godot 3D." % source.map_id
	if not result["missing_tiles"].is_empty():
		message += " Brakujące tekstury: %d." % result["missing_tiles"].size()
	if not result["invalid_tiles"].is_empty():
		message += " Uszkodzone: %d." % result["invalid_tiles"].size()
	return message

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label

func _control_with_label(text: String, control: Control) -> VBoxContainer:
	var container := VBoxContainer.new()
	var label := Label.new()
	label.text = text
	container.add_child(label)
	container.add_child(control)
	return container

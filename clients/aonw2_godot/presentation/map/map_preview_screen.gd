extends Node3D

const OpenMap := preload("res://application/map/open_map.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")
const MapSource := preload("res://application/map/map_source.gd")
const DEFAULT_MAP := "res://assets/maps/aonw2_starter/map.json"

@onready var _surface: AonwMapSurface = %MapSurface
@onready var _camera_rig: AonwOrbitCameraRig = %OrbitCameraRig
@onready var _open_dialog: FileDialog = %OpenMapDialog
@onready var _grid_toggle: CheckButton = %GridToggle
@onready var _legacy_toggle: CheckButton = %LegacyToggle
@onready var _status: Label = %Status

var _open_map := OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new())
var _current_document: AonwMapDocument

func _ready() -> void:
	_surface.map_presented.connect(_on_map_presented)
	_open_dialog.file_selected.connect(_open)
	_open_source(AonwMapSource.new(
		"aonw2_starter",
		DEFAULT_MAP,
		"",
		AonwMapSource.Format.VERSIONED,
		"Godot",
	))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		_grid_toggle.button_pressed = not _grid_toggle.button_pressed
		get_viewport().set_input_as_handled()

func _on_open_pressed() -> void:
	_open_dialog.current_dir = ProjectSettings.globalize_path(DEFAULT_MAP).get_base_dir()
	_open_dialog.popup_centered_ratio(0.8)

func _on_grid_toggled(enabled: bool) -> void:
	_surface.set_grid_visible(enabled)

func _open(source_path: String) -> void:
	var format := (
		AonwMapSource.Format.LEGACY
		if _legacy_toggle.button_pressed
		else AonwMapSource.Format.VERSIONED
	)
	_open_source(AonwMapSource.new(
		source_path.get_base_dir().get_file(),
		source_path,
		source_path.get_base_dir(),
		format,
		"file",
	))

func _open_source(source: AonwMapSource) -> void:
	_status.text = "Wczytywanie mapy…"
	var result := _open_map.execute(source)
	if not result["ok"]:
		_status.text = "Błąd: %s" % result["message"]
		return

	_current_document = result["document"]
	_surface.present(
		_current_document,
		result["terrain_texture"],
		result["reference_texture"],
	)
	var missing: Array = result["missing_tiles"]
	_status.text = "%s · %d×%d" % [
		_current_document.map_name(),
		_current_document.cols(),
		_current_document.rows(),
	]
	if not missing.is_empty():
		_status.text += " · proceduralne pola: %d" % missing.size()
	var invalid: Array = result["invalid_tiles"]
	if not invalid.is_empty():
		_status.text += " · uszkodzone tekstury: %d" % invalid.size()

func _on_map_presented(world_size: Vector2, maximum_height: float) -> void:
	_camera_rig.frame_map(world_size, _current_document.default_zoom(), maximum_height)

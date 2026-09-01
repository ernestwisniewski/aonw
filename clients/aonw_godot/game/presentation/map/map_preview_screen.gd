extends Node3D

const OpenMap := preload("res://game/application/map/open_map.gd")
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://game/infrastructure/map/tile_atlas_repository.gd")
const TerrainArtifactRepository := preload(
	"res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const MapSource := preload("res://game/application/map/map_source.gd")
const LocalMatchSessionController := preload(
	"res://game/application/session/local_match_session_controller.gd"
)
const DEFAULT_MAP := "res://assets/maps/aonw2_starter/map.json"

@onready var _surface: AonwMapSurface = %MapSurface
@onready var _interaction: AonwMapInteractionController = %MapInteraction
@onready var _unit_layer: Node3D = %UnitLayer
@onready var _camera_rig: AonwOrbitCameraRig = %OrbitCameraRig
@onready var _open_dialog: FileDialog = %OpenMapDialog
@onready var _grid_toggle: CheckButton = %GridToggle
@onready var _confirm_move: Button = %ConfirmMove
@onready var _status: Label = %Status

var _open_map := OpenMap.new(
	JsonMapRepository.new(),
	TileAtlasRepository.new(),
	TerrainArtifactRepository.new(),
)
var _local_session := LocalMatchSessionController.new()
var _current_map: AonwMapView
var _selected_unit_id := ""
var _reachable_hexes: Dictionary = {}
var _route: AonwClientReadModels.RoutePlanView

func _ready() -> void:
	_surface.map_presented.connect(_on_map_presented)
	_interaction.hex_selected.connect(_on_hex_selected)
	_open_dialog.file_selected.connect(_open)
	_open_source(AonwMapSource.new(
		"aonw2_starter",
		DEFAULT_MAP,
		DEFAULT_MAP.get_base_dir(),
		"Godot",
	))

func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode in [KEY_ENTER, KEY_KP_ENTER]
		and _route != null
	):
		_on_confirm_move_pressed()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		_grid_toggle.button_pressed = not _grid_toggle.button_pressed
		get_viewport().set_input_as_handled()

func _on_open_pressed() -> void:
	_open_dialog.current_dir = ProjectSettings.globalize_path(DEFAULT_MAP).get_base_dir()
	_open_dialog.popup_centered_ratio(0.8)

func _on_grid_toggled(enabled: bool) -> void:
	_surface.set_grid_visible(enabled)

func _open(source_path: String) -> void:
	_open_source(AonwMapSource.new(
		source_path.get_base_dir().get_file(),
		source_path,
		source_path.get_base_dir(),
		"file",
	))

func _open_source(source: AonwMapSource) -> void:
	_status.text = "Loading map…"
	var result := _open_map.execute(source)
	if not result["ok"]:
		_status.text = "Error: %s" % result["message"]
		return

	_current_map = result["map"]
	_surface.present(
		_current_map,
		result["terrain_artifact"],
		result["reference_texture"],
	)
	_interaction.present(_surface.projection())
	var missing: Array = result["missing_tiles"]
	_status.text = "%s · %d×%d" % [
		_current_map.map_id(),
		_current_map.cols(),
		_current_map.rows(),
	]
	if not missing.is_empty():
		_status.text += " · procedural tiles: %d" % missing.size()
	var invalid: Array = result["invalid_tiles"]
	if not invalid.is_empty():
		_status.text += " · invalid textures: %d" % invalid.size()
	_setup_local_session(source)

func _on_map_presented(world_size: Vector2, maximum_height: float) -> void:
	_camera_rig.frame_map(world_size, _current_map.default_zoom(), maximum_height)

func _on_hex_selected(coordinate: Vector2i) -> void:
	var unit_id: String = _unit_layer.unit_at(coordinate)
	if not unit_id.is_empty():
		_select_unit(unit_id, coordinate)
		return
	if not _selected_unit_id.is_empty() and _reachable_hexes.has(coordinate):
		_preview_selected_route(coordinate)
		return
	_clear_movement_selection()
	_status.text = "%s · hex %d,%d" % [_current_map.map_id(), coordinate.x, coordinate.y]

func _setup_local_session(source: AonwMapSource) -> void:
	_selected_unit_id = ""
	_reachable_hexes.clear()
	_route = null
	_confirm_move.visible = false
	_local_session.close()
	var map_file := FileAccess.open(
		AonwJsonMapRepository.resolve_path(source.map_path),
		FileAccess.READ,
	)
	if map_file == null:
		_status.text += " · Rust map unavailable"
		_present_empty_unit_layer()
		return
	var scenario_path := "res://assets/scenarios/%s.json" % _current_map.map_id()
	var scenario_file := FileAccess.open(scenario_path, FileAccess.READ)
	if scenario_file == null:
		_status.text += " · no local scenario"
		_present_empty_unit_layer()
		return
	var opened := _local_session.open(
		map_file.get_as_text(),
		scenario_file.get_as_text(),
		"preview-player",
	)
	if not opened["ok"]:
		_status.text += " · Rust: %s" % opened["message"]
		_present_empty_unit_layer()
		return
	_refresh_session_snapshot()

func _refresh_session_snapshot() -> bool:
	var snapshot := _local_session.snapshot()
	if not snapshot["ok"]:
		_status.text += " · Rust: %s" % snapshot["message"]
		_present_empty_unit_layer()
		return false
	var value: AonwClientReadModels.SnapshotView = snapshot["value"]
	if value.stamp.map_hash != _current_map.content_hash():
		_status.text += " · Rust snapshot belongs to another map"
		_present_empty_unit_layer()
		return false
	for unit in value.units:
		if not _current_map.contains(unit.coordinate):
			_status.text += " · Rust snapshot contains an out-of-map unit"
			_present_empty_unit_layer()
			return false
	_unit_layer.present(_interaction.projection(), value.units)
	return true

func _present_empty_unit_layer() -> void:
	var units: Array[AonwClientReadModels.UnitView] = []
	_unit_layer.present(_interaction.projection(), units)

func _select_unit(unit_id: String, coordinate: Vector2i) -> void:
	_clear_route_preview()
	var reachable := _local_session.reachable(unit_id)
	if not reachable["ok"]:
		_status.text = "Rust: %s" % reachable["message"]
		return
	_selected_unit_id = unit_id
	_reachable_hexes.clear()
	var coordinates: Array[Vector2i] = []
	var reachable_view: AonwClientReadModels.ReachableView = reachable["value"]
	for tile in reachable_view.tiles:
		var target := tile.coordinate
		_reachable_hexes[target] = true
		coordinates.append(target)
	_interaction.set_reachable_hexes(coordinates)
	_status.text = "%s · unit %s · reachable hexes: %d" % [
		_current_map.map_id(), unit_id, coordinates.size(),
	]
	if _interaction.selected_hex() != coordinate:
		push_error("movement selection is inconsistent with the picked hex")

func _preview_selected_route(target: Vector2i) -> void:
	var planned := _local_session.route_plan(_selected_unit_id, target)
	if not planned["ok"]:
		_status.text = "Rust: %s" % planned["message"]
		return
	var route: AonwClientReadModels.RoutePlanView = planned["value"]
	if (
		route.stamp.map_hash != _current_map.content_hash()
		or route.unit_id != _selected_unit_id
		or route.target != target
		or not _current_map.contains(route.destination)
		or _unit_layer.unit_at(route.steps[0].coordinate) != _selected_unit_id
	):
		_status.text = "Rust returned a route for another request"
		return
	_route = route
	var coordinates: Array[Vector2i] = []
	for step in route.steps:
		if not _current_map.contains(step.coordinate):
			_status.text = "Rust returned an out-of-map route"
			_clear_route_preview()
			return
		coordinates.append(step.coordinate)
	_interaction.set_route_hexes(coordinates)
	_confirm_move.visible = true
	_status.text = "%s · route %s → %d,%d · cost %d · remaining %d" % [
		_current_map.map_id(),
		_selected_unit_id,
		route.destination.x,
		route.destination.y,
		route.total_cost_units,
		route.remaining_movement_units,
	]

func _on_confirm_move_pressed() -> void:
	if _route == null or _selected_unit_id.is_empty():
		return
	_move_selected_unit(_route.target)

func _move_selected_unit(target: Vector2i) -> void:
	var previous_revision := _local_session.revision()
	var moved := _local_session.move_unit(
		_selected_unit_id,
		target,
	)
	if not moved["ok"]:
		_status.text = "Rust: %s" % moved["message"]
		return
	var value: AonwClientReadModels.CommandResult = moved["value"]
	if not value.accepted:
		_status.text = "Rust: %s" % value.rejection
		return
	if value.patch.from_revision != previous_revision:
		_refresh_session_snapshot()
	else:
		_unit_layer.apply_transition(value.patch, value.evidence)
	var selected := _selected_unit_id
	_clear_movement_selection()
	if value.evidence == null:
		_status.text = "%s · command accepted for %s" % [
			_current_map.map_id(), selected,
		]
	else:
		_status.text = "%s · moved %s → %d,%d" % [
			_current_map.map_id(), selected, target.x, target.y,
		]

func _clear_movement_selection() -> void:
	_clear_route_preview()
	_selected_unit_id = ""
	_reachable_hexes.clear()
	_interaction.set_reachable_hexes([])
	_interaction.clear_selection()

func _clear_route_preview() -> void:
	_route = null
	_interaction.set_route_hexes([])
	_confirm_move.visible = false

class_name AonwMapInteractionController
extends Node

signal hex_hovered(coordinate: Vector2i)
signal hex_selected(coordinate: Vector2i)

const INVALID_HEX := Vector2i(-1, -1)

@onready var _surface: AonwMapSurface = %MapSurface
@onready var _overlay: AonwMapOverlayLayer = %MapOverlay
@onready var _camera: Camera3D = %Camera

var _projection: AonwHexMapProjection
var _hovered := INVALID_HEX
var _selected := INVALID_HEX

func present(projection: AonwHexMapProjection) -> void:
	_projection = projection
	_hovered = INVALID_HEX
	_selected = INVALID_HEX
	_overlay.present(_projection)

func selected_hex() -> Vector2i:
	return _selected

func hovered_hex() -> Vector2i:
	return _hovered

func projection() -> AonwHexMapProjection:
	return _projection

func set_reachable_hexes(coordinates: Array) -> void:
	_overlay.set_reachable(coordinates)

func set_route_hexes(coordinates: Array) -> void:
	_overlay.set_route(coordinates)

func clear_selection() -> void:
	_selected = INVALID_HEX
	_overlay.set_selected(INVALID_HEX)

func pick_screen_position(screen_position: Vector2) -> Vector2i:
	if _projection == null:
		return INVALID_HEX
	var inverse := _surface.global_transform.affine_inverse()
	var local_origin := inverse * _camera.project_ray_origin(screen_position)
	var local_direction := (
		inverse.basis * _camera.project_ray_normal(screen_position)
	).normalized()
	return _surface.pick_ray(local_origin, local_direction)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hovered(pick_screen_position(event.position))
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		var coordinate := pick_screen_position(event.position)
		if coordinate != INVALID_HEX:
			_selected = coordinate
			_overlay.set_selected(coordinate)
			hex_selected.emit(coordinate)
			get_viewport().set_input_as_handled()

func _set_hovered(coordinate: Vector2i) -> void:
	if coordinate == _hovered:
		return
	_hovered = coordinate
	_overlay.set_hovered(coordinate)
	hex_hovered.emit(coordinate)

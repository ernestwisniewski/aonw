class_name AonwHexMapProjection
extends RefCounted

const HexGridGeometry := preload("res://domain/map/hex_grid_geometry.gd")
const INVALID_HEX := Vector2i(-1, -1)

var _document: AonwMapDocument
var _geometry: AonwHexGridGeometry
var _map_center: Vector2
var _height_step: float

func _init(
	document: AonwMapDocument,
	hex_radius: float = 1.0,
	height_step: float = 0.16,
) -> void:
	_document = document
	_geometry = HexGridGeometry.new(document.cols(), document.rows(), hex_radius)
	_map_center = _geometry.bounds().get_center()
	_height_step = height_step

func contains(coordinate: Vector2i) -> bool:
	return _geometry.contains(coordinate)

func hex_center(coordinate: Vector2i, vertical_offset: float = 0.0) -> Vector3:
	var center := _geometry.tile_center(coordinate) - _map_center
	return Vector3(center.x, hex_height(coordinate) + vertical_offset, center.y)

func hex_corner(coordinate: Vector2i, corner: int, vertical_offset: float = 0.0) -> Vector3:
	var point := _geometry.corner_position(coordinate, corner) - _map_center
	return Vector3(point.x, hex_height(coordinate) + vertical_offset, point.y)

func hex_height(coordinate: Vector2i) -> float:
	var tile := _document.tile_at(coordinate)
	if tile.is_empty():
		return 0.0
	return float(tile["height"]) * _height_step

func local_to_hex(local_position: Vector3) -> Vector2i:
	var point := Vector2(local_position.x, local_position.z) + _map_center
	var coordinate := _geometry.tile_at_point(point)
	return coordinate if contains(coordinate) else INVALID_HEX

func ray_to_hex(local_origin: Vector3, local_direction: Vector3) -> Vector2i:
	if absf(local_direction.y) < 0.000001:
		return INVALID_HEX
	var best := INVALID_HEX
	var best_distance := INF
	for height in range(AonwMapDocument.MAX_HEIGHT + 1):
		var plane_height := float(height) * _height_step
		var distance := (plane_height - local_origin.y) / local_direction.y
		if distance < 0.0 or distance >= best_distance:
			continue
		var point := local_origin + local_direction * distance
		var coordinate := local_to_hex(point)
		if coordinate == INVALID_HEX:
			continue
		var tile := _document.tile_at(coordinate)
		if int(tile["height"]) != height:
			continue
		best = coordinate
		best_distance = distance
	return best

class_name AonwHexMapProjection
extends RefCounted

const HexGridGeometry := preload("res://presentation/map/geometry/hex_grid_geometry.gd")
const INVALID_HEX := Vector2i(-1, -1)

var _document: AonwMapDocument
var _geometry: AonwHexGridGeometry
var _map_center: Vector2
var _height_step: float
var _corner_heights := {}

func _init(
	document: AonwMapDocument,
	hex_radius: float = 1.0,
	height_step: float = 0.16,
) -> void:
	_document = document
	_geometry = HexGridGeometry.new(document.cols(), document.rows(), hex_radius)
	_map_center = _geometry.bounds().get_center()
	_height_step = height_step
	_corner_heights = _build_corner_heights()

func contains(coordinate: Vector2i) -> bool:
	return _geometry.contains(coordinate)

func hex_center(coordinate: Vector2i, vertical_offset: float = 0.0) -> Vector3:
	var center := _geometry.tile_center(coordinate) - _map_center
	return Vector3(center.x, hex_height(coordinate) + vertical_offset, center.y)

func hex_corner(coordinate: Vector2i, corner: int, vertical_offset: float = 0.0) -> Vector3:
	var point := _geometry.corner_position(coordinate, corner) - _map_center
	var key := _geometry.corner_key(coordinate, corner)
	return Vector3(point.x, float(_corner_heights[key]) + vertical_offset, point.y)

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
	if local_direction.is_zero_approx():
		return INVALID_HEX
	var best := INVALID_HEX
	var best_distance := INF
	for tile in _document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		var center := hex_center(coordinate)
		for corner in 6:
			var intersection: Variant = Geometry3D.ray_intersects_triangle(
				local_origin,
				local_direction,
				center,
				hex_corner(coordinate, (corner + 1) % 6),
				hex_corner(coordinate, corner),
			)
			if intersection == null:
				continue
			var distance := local_origin.distance_to(intersection)
			if distance < best_distance:
				best = coordinate
				best_distance = distance
	return best

func geometry() -> AonwHexGridGeometry:
	return _geometry

func map_center() -> Vector2:
	return _map_center

func corner_keys() -> Array:
	return _corner_heights.keys()

func corner_height(key: Vector2i) -> float:
	return float(_corner_heights[key])

func _build_corner_heights() -> Dictionary:
	var totals := {}
	for tile in _document.tiles():
		var coordinate := Vector2i(tile["col"], tile["row"])
		for corner in 6:
			var key := _geometry.corner_key(coordinate, corner)
			var total: Vector2 = totals.get(key, Vector2.ZERO)
			totals[key] = total + Vector2(float(tile["height"]) * _height_step, 1.0)
	for key in totals:
		var total: Vector2 = totals[key]
		totals[key] = total.x / total.y
	return totals

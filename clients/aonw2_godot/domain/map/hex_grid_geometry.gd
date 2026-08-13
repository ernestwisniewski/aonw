class_name AonwHexGridGeometry
extends RefCounted

const SQRT_3 := 1.7320508075688772
const CORNER_OFFSETS := [
	Vector2i(2, 0),
	Vector2i(1, 1),
	Vector2i(-1, 1),
	Vector2i(-2, 0),
	Vector2i(-1, -1),
	Vector2i(1, -1),
]

var cols: int
var rows: int
var radius: float

func _init(map_cols: int, map_rows: int, hex_radius: float = 1.0) -> void:
	cols = map_cols
	rows = map_rows
	radius = hex_radius

func tile_center(coordinate: Vector2i) -> Vector2:
	var lattice := Vector2i(3 * coordinate.x, 2 * coordinate.y + (coordinate.x & 1))
	return lattice_to_world(lattice)

func corner_key(coordinate: Vector2i, corner: int) -> Vector2i:
	var center := Vector2i(3 * coordinate.x, 2 * coordinate.y + (coordinate.x & 1))
	return center + CORNER_OFFSETS[corner]

func corner_position(coordinate: Vector2i, corner: int) -> Vector2:
	return lattice_to_world(corner_key(coordinate, corner))

func lattice_to_world(key: Vector2i) -> Vector2:
	return Vector2(
		float(key.x) * radius * 0.5,
		float(key.y) * SQRT_3 * radius * 0.5,
	)

func bounds() -> Rect2:
	var minimum := Vector2(-radius, -SQRT_3 * radius * 0.5)
	var maximum_x := float(cols - 1) * 1.5 * radius + radius
	var odd_column_shift := SQRT_3 * radius * 0.5 if cols > 1 else 0.0
	var maximum_y := float(rows - 1) * SQRT_3 * radius + odd_column_shift + SQRT_3 * radius * 0.5
	var maximum := Vector2(maximum_x, maximum_y)
	return Rect2(minimum, maximum - minimum)

func normalized_uv(point: Vector2) -> Vector2:
	var map_bounds := bounds()
	return (point - map_bounds.position) / map_bounds.size

func target_atlas_size(tile_size: Vector2i = Vector2i(160, 120)) -> Vector2i:
	var map_bounds := bounds()
	return Vector2i(
		roundi(map_bounds.size.x * float(tile_size.x) / (2.0 * radius)),
		roundi(map_bounds.size.y * float(tile_size.y) / (SQRT_3 * radius)),
	)

func tile_slice_rect(
	coordinate: Vector2i,
	atlas_size: Vector2i,
) -> Rect2i:
	var map_bounds := bounds()
	var center := tile_center(coordinate) - map_bounds.position
	var scale := Vector2(atlas_size) / map_bounds.size
	var top_left := Vector2(center.x - radius, center.y - SQRT_3 * radius * 0.5) * scale
	var bottom_right := Vector2(center.x + radius, center.y + SQRT_3 * radius * 0.5) * scale
	var clipped_top_left := top_left.clamp(Vector2.ZERO, Vector2(atlas_size))
	var clipped_bottom_right := bottom_right.clamp(Vector2.ZERO, Vector2(atlas_size))
	return Rect2i(
		Vector2i(roundi(clipped_top_left.x), roundi(clipped_top_left.y)),
		Vector2i(
			roundi(clipped_bottom_right.x - clipped_top_left.x),
			roundi(clipped_bottom_right.y - clipped_top_left.y),
		),
	)

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

func tile_at_point(point: Vector2) -> Vector2i:
	var approximate_col := roundi(point.x / (1.5 * radius))
	var approximate_row := roundi(
		(point.y - float(approximate_col & 1) * SQRT_3 * radius * 0.5)
		/ (SQRT_3 * radius)
	)
	var best := Vector2i(approximate_col, approximate_row)
	var best_distance := point.distance_squared_to(tile_center(best))
	for col_offset in range(-1, 2):
		for row_offset in range(-1, 2):
			var candidate := Vector2i(approximate_col + col_offset, approximate_row + row_offset)
			var distance := point.distance_squared_to(tile_center(candidate))
			if distance < best_distance:
				best = candidate
				best_distance = distance
	return best

func contains(coordinate: Vector2i) -> bool:
	return coordinate.x >= 0 and coordinate.x < cols and coordinate.y >= 0 and coordinate.y < rows

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

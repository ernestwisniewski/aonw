class_name AonwMapDocument
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_HEIGHT := 5

var _map_id: String
var _cols: int
var _rows: int
var _default_zoom: float
var _objectives: Array[Dictionary]
var _tiles: Array[Dictionary]
var _tiles_by_coordinate: Dictionary

func _init(
	map_id: String,
	cols: int,
	rows: int,
	default_zoom: float,
	objectives: Array[Dictionary],
	tiles: Array[Dictionary],
) -> void:
	_map_id = map_id
	_cols = cols
	_rows = rows
	_default_zoom = default_zoom
	_objectives = objectives
	_tiles = tiles
	_tiles_by_coordinate = {}
	for tile in _tiles:
		_tiles_by_coordinate[Vector2i(tile["col"], tile["row"])] = tile
	_tiles_by_coordinate.make_read_only()

static func from_native_snapshot(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return _failure("Rust render document must be an object")
	for field in [
		"schemaVersion", "gridLayout", "cols", "rows", "mapName",
		"defaultZoom", "objectives", "tiles",
	]:
		if not raw.has(field):
			return _failure("Rust render document is missing %s" % field)
	if int(raw["schemaVersion"]) != SCHEMA_VERSION:
		return _failure("Rust render document has an unsupported schemaVersion")
	if not raw["objectives"] is Array or not raw["tiles"] is Array:
		return _failure("Rust render document collections are invalid")

	var objectives: Array[Dictionary] = []
	for raw_objective in raw["objectives"]:
		if not raw_objective is Dictionary:
			return _failure("Rust render objective must be an object")
		var objective: Dictionary = raw_objective.duplicate(true)
		objective.make_read_only()
		objectives.append(objective)
	objectives.make_read_only()

	var tiles: Array[Dictionary] = []
	for raw_tile in raw["tiles"]:
		if not raw_tile is Dictionary:
			return _failure("Rust render tile must be an object")
		var tile: Dictionary = raw_tile.duplicate(true)
		var terrains: Array = tile["terrains"]
		var resources: Array = tile["resources"]
		terrains.make_read_only()
		resources.make_read_only()
		tile.make_read_only()
		tiles.append(tile)
	tiles.make_read_only()

	return {
		"ok": true,
		"value": AonwMapDocument.new(
			str(raw["mapName"]),
			int(raw["cols"]),
			int(raw["rows"]),
			float(raw["defaultZoom"]),
			objectives,
			tiles,
		),
	}

func map_id() -> String:
	return _map_id

func map_name() -> String:
	return _map_id

func cols() -> int:
	return _cols

func rows() -> int:
	return _rows

func default_zoom() -> float:
	return _default_zoom

func objectives() -> Array[Dictionary]:
	return _objectives

func tiles() -> Array[Dictionary]:
	return _tiles

func tile_at(coordinate: Vector2i) -> Dictionary:
	return _tiles_by_coordinate.get(coordinate, {})

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

class_name AonwMapDocument
extends RefCounted

const TerrainCatalog := preload("res://domain/map/terrain_catalog.gd")
const ResourceCatalog := preload("res://domain/map/resource_catalog.gd")

const SCHEMA_VERSION := 1
const GRID_LAYOUT := "oddQFlatTop"
const MIN_COLS := 5
const MAX_COLS := 40
const MIN_ROWS := 5
const MAX_ROWS := 30
const MAX_HEIGHT := 5

var _map_name: String
var _cols: int
var _rows: int
var _default_zoom: float
var _tiles: Array[Dictionary]
var _tiles_by_coordinate: Dictionary

func _init(
	map_name: String,
	cols: int,
	rows: int,
	default_zoom: float,
	tiles: Array[Dictionary],
) -> void:
	_map_name = map_name
	_cols = cols
	_rows = rows
	_default_zoom = default_zoom
	_tiles = tiles
	_tiles_by_coordinate = {}
	for tile in _tiles:
		_tiles_by_coordinate[Vector2i(tile["col"], tile["row"])] = tile

static func create(raw: Dictionary, accept_legacy: bool = false) -> Dictionary:
	var header_error := _validate_header(raw, accept_legacy)
	if not header_error.is_empty():
		return _failure(header_error)

	var cols := int(raw["cols"])
	var rows := int(raw["rows"])
	var map_name := str(raw.get("mapName", ""))
	var default_zoom := float(raw.get("defaultZoom", 1.0))
	if cols < MIN_COLS or cols > MAX_COLS:
		return _failure("cols must be in %d..%d" % [MIN_COLS, MAX_COLS])
	if rows < MIN_ROWS or rows > MAX_ROWS:
		return _failure("rows must be in %d..%d" % [MIN_ROWS, MAX_ROWS])
	if not _valid_content_id(map_name):
		return _failure("mapName is not a valid content identifier")
	if not is_finite(default_zoom) or default_zoom <= 0.0:
		return _failure("defaultZoom must be finite and positive")

	var raw_tiles: Array = raw["tiles"]
	if raw_tiles.size() != cols * rows:
		return _failure("tiles must cover the complete grid")
	var normalized: Array[Dictionary] = []
	var coordinates := {}
	for index in raw_tiles.size():
		var tile_result := _normalize_tile(raw_tiles[index], index, cols, rows)
		if not tile_result["ok"]:
			return tile_result
		var tile: Dictionary = tile_result["value"]
		var coordinate := Vector2i(tile["col"], tile["row"])
		if coordinates.has(coordinate):
			return _failure("duplicate tile at (%d, %d)" % [coordinate.x, coordinate.y])
		coordinates[coordinate] = true
		normalized.append(tile)

	normalized.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return left["row"] < right["row"] or (
			left["row"] == right["row"] and left["col"] < right["col"]
		)
	)
	for index in normalized.size():
		var expected := Vector2i(index % cols, index / cols)
		var tile := normalized[index]
		if Vector2i(tile["col"], tile["row"]) != expected:
			return _failure("tiles must contain every coordinate exactly once")

	return {
		"ok": true,
		"value": AonwMapDocument.new(map_name, cols, rows, default_zoom, normalized),
	}

func map_name() -> String:
	return _map_name

func cols() -> int:
	return _cols

func rows() -> int:
	return _rows

func default_zoom() -> float:
	return _default_zoom

func tiles() -> Array[Dictionary]:
	return _tiles

func tile_at(coordinate: Vector2i) -> Dictionary:
	return _tiles_by_coordinate.get(coordinate, {})

static func _validate_header(raw: Dictionary, accept_legacy: bool) -> String:
	for field in ["cols", "rows", "mapName", "tiles"]:
		if not raw.has(field):
			return "missing field %s" % field
	if not _is_integer(raw["cols"]) or not _is_integer(raw["rows"]):
		return "cols and rows must be integers"
	if not raw["tiles"] is Array:
		return "tiles must be an array"

	var has_version := raw.has("schemaVersion")
	var has_layout := raw.has("gridLayout")
	if not has_version and not has_layout:
		return "" if accept_legacy else "schemaVersion and gridLayout are required"
	if not has_version or not has_layout:
		return "schemaVersion and gridLayout must be provided together"
	if not _is_integer(raw["schemaVersion"]) or int(raw["schemaVersion"]) != SCHEMA_VERSION:
		return "unsupported schemaVersion"
	if raw["gridLayout"] != GRID_LAYOUT:
		return "gridLayout must be %s" % GRID_LAYOUT
	return ""

static func _normalize_tile(
	raw: Variant,
	index: int,
	cols: int,
	rows: int,
) -> Dictionary:
	if not raw is Dictionary:
		return _failure("tiles[%d] must be an object" % index)
	for field in ["col", "row", "terrains", "resources", "height"]:
		if not raw.has(field):
			return _failure("tiles[%d] is missing %s" % [index, field])
	if not _is_integer(raw["col"]) or not _is_integer(raw["row"]) or not _is_integer(raw["height"]):
		return _failure("tiles[%d] coordinates and height must be integers" % index)

	var col := int(raw["col"])
	var row := int(raw["row"])
	var height := int(raw["height"])
	if col < 0 or col >= cols or row < 0 or row >= rows:
		return _failure("tiles[%d] is outside map bounds" % index)
	if height < 0 or height > MAX_HEIGHT:
		return _failure("tiles[%d].height must be in 0..%d" % [index, MAX_HEIGHT])
	if not raw["terrains"] is Array or raw["terrains"].is_empty():
		return _failure("tiles[%d].terrains must be a non-empty array" % index)
	if not raw["resources"] is Array:
		return _failure("tiles[%d].resources must be an array" % index)

	var terrains: Array[String] = []
	for terrain in raw["terrains"]:
		if not terrain is String or not TerrainCatalog.contains(terrain):
			return _failure("tiles[%d] contains unknown terrain" % index)
		if terrains.has(terrain):
			return _failure("tiles[%d] contains duplicate terrain" % index)
		terrains.append(terrain)

	var resources: Array[String] = []
	for resource in raw["resources"]:
		if not resource is String or not ResourceCatalog.contains(resource):
			return _failure("tiles[%d] contains unknown resource" % index)
		if resources.has(resource):
			return _failure("tiles[%d] contains duplicate resource" % index)
		resources.append(resource)
	resources.sort()
	return {
		"ok": true,
		"value": {
			"col": col,
			"row": row,
			"terrains": terrains,
			"resources": resources,
			"height": height,
		},
	}

static func _valid_content_id(value: String) -> bool:
	if value.is_empty() or value.length() > 64:
		return false
	var expression := RegEx.create_from_string("^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$")
	return expression.search(value) != null

static func _is_integer(value: Variant) -> bool:
	return value is int or (value is float and value == floorf(value))

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

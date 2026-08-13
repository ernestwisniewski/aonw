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
const VERSIONED_ROOT_FIELDS := [
	"schemaVersion",
	"gridLayout",
	"cols",
	"rows",
	"mapName",
	"defaultZoom",
	"objectives",
	"tiles",
]
const LEGACY_ROOT_FIELDS := ["cols", "rows", "mapName", "objectives", "tiles"]
const TILE_FIELDS := ["col", "row", "terrains", "resources", "height"]
const OBJECTIVE_FIELDS := [
	"id",
	"type",
	"hex",
	"requiredHoldTurns",
	"victoryPoints",
	"goldPerTurn",
]
const COORDINATE_FIELDS := ["col", "row"]
const OBJECTIVE_TYPES := ["ruins", "strategicPass", "holySite", "legendaryResource"]

static var _content_id_expression := RegEx.create_from_string(
	"^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$"
)

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

static func create_versioned(raw: Dictionary) -> Dictionary:
	return _create(raw, false)

static func create_legacy(raw: Dictionary) -> Dictionary:
	return _create(raw, true)

static func _create(raw: Dictionary, legacy: bool) -> Dictionary:
	var header_error := _validate_header(raw, legacy)
	if not header_error.is_empty():
		return _failure(header_error)

	var cols := int(raw["cols"])
	var rows := int(raw["rows"])
	var map_id := str(raw["mapName"])
	var default_zoom := float(raw.get("defaultZoom", 1.0))
	if cols < MIN_COLS or cols > MAX_COLS:
		return _failure("cols must be in %d..%d" % [MIN_COLS, MAX_COLS])
	if rows < MIN_ROWS or rows > MAX_ROWS:
		return _failure("rows must be in %d..%d" % [MIN_ROWS, MAX_ROWS])
	if not _valid_content_id(map_id):
		return _failure("mapName is not a valid content identifier")
	if not is_finite(default_zoom) or default_zoom <= 0.0:
		return _failure("defaultZoom must be finite and positive")

	var objective_result := _normalize_objectives(raw["objectives"], cols, rows)
	if not objective_result["ok"]:
		return objective_result

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

	var objectives: Array[Dictionary] = objective_result["value"]
	objectives.make_read_only()
	normalized.make_read_only()
	return {
		"ok": true,
		"value": AonwMapDocument.new(
			map_id,
			cols,
			rows,
			default_zoom,
			objectives,
			normalized,
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

static func _validate_header(raw: Dictionary, legacy: bool) -> String:
	var expected_fields := LEGACY_ROOT_FIELDS if legacy else VERSIONED_ROOT_FIELDS
	var fields_error := _validate_exact_fields(raw, expected_fields, "map")
	if not fields_error.is_empty():
		return fields_error
	if not _is_integer(raw["cols"]) or not _is_integer(raw["rows"]):
		return "cols and rows must be integers"
	if not raw["objectives"] is Array:
		return "objectives must be an array"
	if not raw["tiles"] is Array:
		return "tiles must be an array"
	if legacy:
		return ""
	if not _is_integer(raw["schemaVersion"]) or int(raw["schemaVersion"]) != SCHEMA_VERSION:
		return "unsupported schemaVersion"
	if raw["gridLayout"] != GRID_LAYOUT:
		return "gridLayout must be %s" % GRID_LAYOUT
	if not raw["defaultZoom"] is float and not raw["defaultZoom"] is int:
		return "defaultZoom must be a number"
	return ""

static func _normalize_objectives(raw_objectives: Array, cols: int, rows: int) -> Dictionary:
	var normalized: Array[Dictionary] = []
	var identifiers := {}
	var coordinates := {}
	for index in raw_objectives.size():
		var raw: Variant = raw_objectives[index]
		if not raw is Dictionary:
			return _failure("objectives[%d] must be an object" % index)
		var fields_error := _validate_exact_fields(raw, OBJECTIVE_FIELDS, "objectives[%d]" % index)
		if not fields_error.is_empty():
			return _failure(fields_error)
		if not raw["id"] is String or not _valid_content_id(raw["id"]):
			return _failure("objectives[%d].id is not a valid content identifier" % index)
		if not raw["type"] is String or not raw["type"] in OBJECTIVE_TYPES:
			return _failure("objectives[%d].type is unknown" % index)
		if not raw["hex"] is Dictionary:
			return _failure("objectives[%d].hex must be an object" % index)
		var hex: Dictionary = raw["hex"]
		var hex_error := _validate_exact_fields(hex, COORDINATE_FIELDS, "objectives[%d].hex" % index)
		if not hex_error.is_empty():
			return _failure(hex_error)
		if not _is_integer(hex["col"]) or not _is_integer(hex["row"]):
			return _failure("objectives[%d].hex coordinates must be integers" % index)
		var coordinate := Vector2i(int(hex["col"]), int(hex["row"]))
		if coordinate.x < 0 or coordinate.x >= cols or coordinate.y < 0 or coordinate.y >= rows:
			return _failure("objectives[%d].hex is outside map bounds" % index)
		for field in ["requiredHoldTurns", "victoryPoints", "goldPerTurn"]:
			if not _is_integer(raw[field]):
				return _failure("objectives[%d].%s must be an integer" % [index, field])
		if int(raw["requiredHoldTurns"]) < 1:
			return _failure("objectives[%d].requiredHoldTurns must be positive" % index)
		if int(raw["victoryPoints"]) < 0 or int(raw["goldPerTurn"]) < 0:
			return _failure("objectives[%d] rewards must be non-negative" % index)
		var objective_id: String = raw["id"]
		if identifiers.has(objective_id):
			return _failure("duplicate objective id %s" % objective_id)
		if coordinates.has(coordinate):
			return _failure("multiple objectives at (%d, %d)" % [coordinate.x, coordinate.y])
		identifiers[objective_id] = true
		coordinates[coordinate] = true
		var normalized_hex := {"col": coordinate.x, "row": coordinate.y}
		normalized_hex.make_read_only()
		var objective := {
			"id": objective_id,
			"type": raw["type"],
			"hex": normalized_hex,
			"requiredHoldTurns": int(raw["requiredHoldTurns"]),
			"victoryPoints": int(raw["victoryPoints"]),
			"goldPerTurn": int(raw["goldPerTurn"]),
		}
		objective.make_read_only()
		normalized.append(objective)
	normalized.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return left["id"] < right["id"]
	)
	return {"ok": true, "value": normalized}

static func _normalize_tile(
	raw: Variant,
	index: int,
	cols: int,
	rows: int,
) -> Dictionary:
	if not raw is Dictionary:
		return _failure("tiles[%d] must be an object" % index)
	var fields_error := _validate_exact_fields(raw, TILE_FIELDS, "tiles[%d]" % index)
	if not fields_error.is_empty():
		return _failure(fields_error)
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
	terrains.make_read_only()
	resources.make_read_only()
	var tile := {
		"col": col,
		"row": row,
		"terrains": terrains,
		"resources": resources,
		"height": height,
	}
	tile.make_read_only()
	return {"ok": true, "value": tile}

static func _validate_exact_fields(raw: Dictionary, expected: Array, context: String) -> String:
	for field in expected:
		if not raw.has(field):
			return "%s is missing %s" % [context, field]
	for field in raw:
		if not field in expected:
			return "%s contains unknown field %s" % [context, field]
	return ""

static func _valid_content_id(value: String) -> bool:
	return (
		not value.is_empty()
		and value.length() <= 64
		and _content_id_expression.search(value) != null
	)

static func _is_integer(value: Variant) -> bool:
	return value is int or (value is float and value == floorf(value))

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

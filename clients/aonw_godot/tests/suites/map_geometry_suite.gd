extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const OpenMap := preload("res://game/application/map/open_map.gd")
const HexGridGeometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const HexMapProjection := preload("res://game/presentation/map/hex_map_projection.gd")
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://game/infrastructure/map/tile_atlas_repository.gd")
const TerrainArtifactRepository := preload(
	"res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const MapSurface := preload("res://game/presentation/map/map_surface.gd")
const GEOMETRY_FIXTURE := "res://../../aonw_tests/fixtures/geometry/odd_q_flat_top.v1.json"
const IDENTITY_FIXTURE := (
	"res://../../aonw_tests/fixtures/maps/aonw2_starter/map_view_identity.v1.json"
)

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_geometry()
	await _test_map_projection()

func _test_geometry() -> void:
	_test_shared_geometry_vectors()
	var geometry := HexGridGeometry.new(25, 19)
	_check(
		geometry.corner_key(Vector2i(0, 0), 0) == geometry.corner_key(Vector2i(1, 0), 4)
		and geometry.corner_key(Vector2i(0, 0), 1) == geometry.corner_key(Vector2i(1, 0), 3),
		"adjacent odd-q hexes share exact corner keys",
	)
	var map_bounds := geometry.bounds().grow(0.001)
	for col in geometry.cols:
		for row in geometry.rows:
			var coordinate := Vector2i(col, row)
			_check(
				geometry.tile_at_point(geometry.tile_center(coordinate)) == coordinate,
				"world-to-hex round-trip preserves tile centers",
			)
			for corner in 6:
				_check(
					map_bounds.has_point(geometry.corner_position(coordinate, corner)),
					"map bounds contain every corner",
				)

func _test_shared_geometry_vectors() -> void:
	var fixture_file := FileAccess.open(
		ProjectSettings.globalize_path(GEOMETRY_FIXTURE),
		FileAccess.READ,
	)
	_check(fixture_file != null, "shared geometry fixture opens")
	if fixture_file == null:
		return
	var fixture: Variant = JSON.parse_string(fixture_file.get_as_text())
	_check(fixture is Dictionary, "shared geometry fixture parses")
	if fixture is not Dictionary:
		return
	var map: Dictionary = fixture["map"]
	var geometry := HexGridGeometry.new(
		int(map["cols"]),
		int(map["rows"]),
		float(fixture["radius"]),
	)
	for vector in fixture["centers"]:
		_check_vector(
			geometry.tile_center(_hex(vector["hex"])),
			vector["point"],
			"shared center vector matches",
		)
	for vector in fixture["corners"]:
		var coordinate := _hex(vector["hex"])
		for index in vector["points"].size():
			_check_vector(
				geometry.corner_position(coordinate, index),
				vector["points"][index],
				"shared corner vector matches",
			)
	var expected_bounds: Array = fixture["bounds"]
	var bounds := geometry.bounds()
	_check_vector(bounds.position, expected_bounds.slice(0, 2), "shared bounds origin matches")
	_check_vector(bounds.size, expected_bounds.slice(2, 4), "shared bounds size matches")
	for vector in fixture["neighbors"]:
		var expected: Array[Vector2i] = []
		for value in vector["hexes"]:
			expected.append(_hex(value))
		_check(
			geometry.neighbors(_hex(vector["hex"])) == expected,
			"shared neighbor vector matches",
		)
	for vector in fixture["picks"]:
		_check(
			geometry.tile_at_point(_point(vector["point"])) == _hex(vector["hex"]),
			"shared picking vector matches",
		)
	var texture_projection := preload(
		"res://game/presentation/map/geometry/map_texture_projection.gd"
	).new(geometry)
	for vector in fixture["uv"]:
		_check_vector(
			texture_projection.normalized_uv(_point(vector["point"])),
			vector["normalized"],
			"shared UV vector matches",
		)

func _test_map_projection() -> void:
	var result: Dictionary = _open_map().execute(MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	))
	_check(result["ok"], "projection fixture map opens")
	if not result["ok"]:
		return
	var map: AonwMapView = result["map"]
	_test_shared_map_identity(map)
	_test_bundle_content_identity(map)
	var camera := Camera3D.new()
	camera.current = true
	Engine.get_main_loop().root.add_child(camera)
	var surface := MapSurface.new()
	Engine.get_main_loop().root.add_child(surface)
	await Engine.get_main_loop().process_frame
	surface.present(map, result["terrain_artifact"], result["reference_texture"])
	var projection: AonwHexMapProjection = surface.projection()
	_check(projection != null, "Terrain3D map projection is created")
	if projection == null:
		surface.free()
		camera.free()
		return
	for coordinate in [Vector2i(0, 0), Vector2i(2, 3), Vector2i(4, 4)]:
		var center: Vector3 = projection.hex_center(coordinate)
		_check(
			projection.local_to_hex(center) == coordinate,
			"render projection preserves hex centers",
		)
		var picked := projection.ray_to_hex(
			center + Vector3(0.0, 10.0, 0.0),
			Vector3.DOWN,
		)
		_check(picked == coordinate, "vertical ray selects the expected hex")
	var slope_coordinate := Vector2i(4, 5)
	var slope_target := projection.hex_center(slope_coordinate).lerp(
		projection.hex_corner(slope_coordinate, 0),
		0.6,
	)
	var slope_origin := slope_target + Vector3(0.2, 5.0, 0.2)
	_check(
		projection.ray_to_hex(
			slope_origin,
			(slope_target - slope_origin).normalized(),
		) == slope_coordinate,
		"angled ray follows the rendered slope triangles",
	)
	_check(
		projection.ray_to_hex(Vector3.ZERO, Vector3.ZERO) == HexMapProjection.INVALID_HEX,
		"zero-length ray does not select a hex",
	)
	_check(surface.terrain() is Terrain3D, "runtime terrain backend is Terrain3D")
	_check(
		surface.find_child("BaseTerrain", true, false) == null,
		"runtime has no mesh terrain fallback",
	)
	surface.free()
	camera.free()

func _test_shared_map_identity(map: AonwMapView) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(IDENTITY_FIXTURE), FileAccess.READ)
	_check(file != null, "shared MapView identity fixture opens")
	if file == null:
		return
	var identity: Variant = JSON.parse_string(file.get_as_text())
	_check(identity is Dictionary, "shared MapView identity fixture parses")
	if identity is not Dictionary:
		return
	_check(
		map.map_id() == StringName(identity["mapId"])
		and map.content_hash() == identity["contentHash"]
		and map.grid_layout() == StringName(identity["gridLayout"])
		and map.cols() == int(identity["cols"])
		and map.rows() == int(identity["rows"]),
		"Godot MapView matches the shared client identity",
	)

func _test_bundle_content_identity(map: AonwMapView) -> void:
	var source_path := ProjectSettings.globalize_path(
		"res://assets/maps/aonw2_starter/map_texture_manifest.json"
	)
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	_check(source_file != null, "starter bundle manifest opens")
	if source_file == null:
		return
	var manifest: Dictionary = JSON.parse_string(source_file.get_as_text())
	manifest["mapContentHash"] = "0".repeat(64)
	var invalid_directory := ProjectSettings.globalize_path("user://invalid-map-bundle")
	DirAccess.make_dir_recursive_absolute(invalid_directory)
	var invalid_manifest_path := invalid_directory.path_join("map_texture_manifest.json")
	var invalid_file := FileAccess.open(invalid_manifest_path, FileAccess.WRITE)
	_check(invalid_file != null, "invalid bundle fixture can be written")
	if invalid_file == null:
		return
	invalid_file.store_string(JSON.stringify(manifest))
	invalid_file.close()
	var result := TileAtlasRepository.new().load_atlas(map, invalid_directory)
	_check(
		not result["ok"] and "map content hash does not match" in result["message"],
		"bundle for a different map content hash is rejected",
	)
	DirAccess.remove_absolute(invalid_manifest_path)
	DirAccess.remove_absolute(invalid_directory)

func _open_map():
	return OpenMap.new(
		JsonMapRepository.new(),
		TileAtlasRepository.new(),
		TerrainArtifactRepository.new(),
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _hex(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _check_vector(actual: Vector2, expected: Array, message: String) -> void:
	_check(
		actual.is_equal_approx(_point(expected)),
		"%s: %s != %s" % [message, actual, expected],
	)

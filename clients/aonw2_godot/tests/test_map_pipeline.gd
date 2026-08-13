extends SceneTree

const OpenMap := preload("res://application/map/open_map.gd")
const MeshBuilder := preload("res://presentation/map/map_surface_mesh_builder.gd")
const HexGridGeometry := preload("res://domain/map/hex_grid_geometry.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_geometry()
	var source_path := ProjectSettings.globalize_path(
		"res://../../assets/maps/myranth/map.json"
	)
	var result := OpenMap.new(
		JsonMapRepository.new(),
		TileAtlasRepository.new(),
	).execute(source_path)
	_check(result["ok"], "legacy map opens")
	if result["ok"]:
		var document: AonwMapDocument = result["document"]
		var texture: Texture2D = result["texture"]
		_check(document.map_name() == "myranth", "map identity is retained")
		_check(document.tiles().size() == 475, "complete map is normalized")
		_check(result["missing_tiles"].is_empty(), "all map textures load")
		_check(texture.get_width() > 0 and texture.get_height() > 0, "atlas is created")
		var atlas := texture.get_image()
		var center := Vector2i(atlas.get_width() / 2, atlas.get_height() / 2)
		_check(atlas.get_pixelv(center).get_luminance() > 0.05, "atlas contains source imagery")

		var meshes := MeshBuilder.new().build(document, texture, 1.0, 0.16)
		var terrain: ArrayMesh = meshes["terrain_mesh"]
		var grid: ArrayMesh = meshes["grid_mesh"]
		_check(terrain.get_surface_count() == 1, "terrain mesh is built")
		_check(grid.get_surface_count() == 1, "grid overlay is built")
		_check(
			terrain.surface_get_array_index_len(0) == document.tiles().size() * 18,
			"terrain contains six triangles per hex",
		)

	if _failures.is_empty():
		print("map pipeline: OK")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _test_geometry() -> void:
	var geometry := HexGridGeometry.new(25, 19)
	_check(
		geometry.corner_key(Vector2i(0, 0), 0) == geometry.corner_key(Vector2i(1, 0), 4)
		and geometry.corner_key(Vector2i(0, 0), 1) == geometry.corner_key(Vector2i(1, 0), 3),
		"adjacent odd-q hexes share exact corner keys",
	)
	var map_bounds := geometry.bounds().grow(0.001)
	for col in geometry.cols:
		for row in geometry.rows:
			for corner in 6:
				_check(
					map_bounds.has_point(geometry.corner_position(Vector2i(col, row), corner)),
					"map bounds contain every corner",
				)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

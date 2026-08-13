extends SceneTree

const GenerateGodotMap := preload("res://application/map/generate_godot_map.gd")
const MapSource := preload("res://application/map/map_source.gd")
const OpenMap := preload("res://application/map/open_map.gd")
const MapDocument := preload("res://domain/map/map_document.gd")
const MeshBuilder := preload("res://presentation/map/map_surface_mesh_builder.gd")
const HexGridGeometry := preload("res://domain/map/hex_grid_geometry.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const MapAssetCatalog := preload("res://infrastructure/map/map_asset_catalog.gd")
const GodotMapSceneRepository := preload("res://infrastructure/map/godot_map_scene_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_geometry()
	_test_strict_document_boundary()
	_test_catalog()
	_test_legacy_map()
	_test_generated_godot_scene()

	if _failures.is_empty():
		print("map pipeline: OK")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _test_legacy_map() -> void:
	var source := MapSource.new(
		"myranth",
		"res://../../assets/maps/myranth/map.json",
		"res://../../assets/maps/myranth",
		AonwMapSource.Format.LEGACY,
		"assets",
	)
	var result := _open_map().execute(source)
	_check(result["ok"], "legacy map opens only through an explicit source format")
	if not result["ok"]:
		return
	var document: AonwMapDocument = result["document"]
	var terrain_texture: Texture2D = result["terrain_texture"]
	var reference_texture: Texture2D = result["reference_texture"]
	_check(document.map_id() == "myranth", "map identity is retained")
	_check(document.tiles().size() == 475, "complete map is normalized")
	_check(document.tiles().is_read_only(), "tile collection is immutable")
	_check(document.tiles()[0].is_read_only(), "tile values are immutable")
	_check(document.objectives().size() == 2, "objectives are retained")
	_check(result["missing_tiles"].is_empty(), "all map textures load")
	_check(result["invalid_tiles"].is_empty(), "all map textures decode")
	_check(reference_texture.get_width() > 0, "reference atlas is created")
	var atlas := reference_texture.get_image()
	var center := Vector2i(atlas.get_width() / 2, atlas.get_height() / 2)
	_check(atlas.get_pixelv(center).get_luminance() > 0.05, "reference atlas contains source imagery")

	var meshes := MeshBuilder.new().build(
		document,
		terrain_texture,
		reference_texture,
		1.0,
		0.16,
	)
	var terrain: ArrayMesh = meshes["terrain_mesh"]
	var reference: ArrayMesh = meshes["reference_mesh"]
	var grid: ArrayMesh = meshes["grid_mesh"]
	_check(terrain.get_surface_count() == 1, "terrain mesh is built")
	_check(reference.get_surface_count() == 1, "reference mesh is built")
	_check(grid.get_surface_count() == 1, "grid overlay is built")
	_check(
		terrain.surface_get_array_index_len(0) == document.tiles().size() * 18,
		"terrain contains six triangles per hex",
	)

func _test_generated_godot_scene() -> void:
	var source := MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		AonwMapSource.Format.VERSIONED,
		"Godot",
	)
	var scene_repository := GodotMapSceneRepository.new(
		"res://.godot/map_generation_test/scenes",
		"res://.godot/map_generation_test/assets",
	)
	var generator := GenerateGodotMap.new(_open_map(), scene_repository)
	var result := generator.execute(source, {
		"height_step": 0.2,
		"reference_opacity": 0.45,
		"grid_visible": true,
	})
	_check(result["ok"], "starter map is saved as a self-contained Godot scene")
	if not result["ok"]:
		return
	var scene_path := scene_repository.scene_path_for("aonw2_starter")
	_check(ResourceLoader.exists(scene_path), "generated Godot scene exists")
	_check(
		FileAccess.file_exists(
			"res://.godot/map_generation_test/assets/aonw2_starter/reference_texture.res"
		),
		"generated scene owns a persisted reference texture",
	)
	_check(
		FileAccess.file_exists(
			"res://.godot/map_generation_test/assets/aonw2_starter/manifest.json"
		),
		"generated scene owns a source manifest",
	)
	var packed := ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	_check(packed != null, "generated Godot scene loads")
	if packed == null:
		return
	var instance := packed.instantiate() as AonwMapSurface
	_check(instance != null, "generated scene owns an Aonw map surface")
	if instance != null:
		_check(
			instance.source_map_path.begins_with(
				"res://.godot/map_generation_test/assets/aonw2_starter/"
			),
			"generated scene points at its bundled map snapshot",
		)
		_check(
			is_equal_approx(instance.reference_opacity, 0.45),
			"reference opacity is persisted",
		)
		_check(instance.terrain_mesh() != null, "generated scene retains terrain mesh")
		_check(instance.reference_mesh() != null, "generated scene retains reference texture mesh")
		_check(instance.grid_mesh() != null, "generated scene retains grid mesh")
		instance.free()

func _test_strict_document_boundary() -> void:
	var raw := {
		"schemaVersion": 1,
		"gridLayout": "oddQFlatTop",
		"cols": 5,
		"rows": 5,
		"mapName": "strict_test",
		"objectives": [],
		"tiles": [],
	}
	var strict_result := MapDocument.create_versioned(raw)
	_check(not strict_result["ok"], "strict documents require defaultZoom")
	var legacy_result := MapDocument.create_legacy(raw)
	_check(not legacy_result["ok"], "legacy mode rejects versioned-only fields")

func _test_catalog() -> void:
	var sources := MapAssetCatalog.new().discover()
	var identifiers: Array[String] = []
	for source in sources:
		identifiers.append(source.map_id)
	_check("myranth" in identifiers, "catalog discovers maps from root assets")
	_check("aonw2_starter" in identifiers, "catalog discovers versioned Godot maps")

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

func _open_map() -> AonwOpenMap:
	return OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new())

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

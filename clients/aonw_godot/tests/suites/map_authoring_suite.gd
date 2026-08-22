extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const OpenMap := preload("res://game/application/map/open_map.gd")
const MeshBuilder := preload("res://game/presentation/map/map_surface_mesh_builder.gd")
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const MapAssetCatalog := preload(
	"res://editor/map_authoring/infrastructure/map_asset_catalog.gd"
)
const TileAtlasRepository := preload("res://game/infrastructure/map/tile_atlas_repository.gd")
const RenderSettings := preload("res://game/presentation/map/map_render_settings.gd")

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_catalog()
	_test_every_catalog_bundle_matches_map()
	_test_display_terrain_color()
	_test_canonical_map_with_runtime_texture()

func _test_display_terrain_color() -> void:
	var color: Color = TileAtlasRepository.new()._terrain_color({
		"terrains": ["mountain", "forest"],
		"displayTerrain": "ocean",
	})
	_check(
		color.is_equal_approx(Color("245b91")),
		"base style uses displayTerrain instead of movement terrain order",
	)

func _test_canonical_map_with_runtime_texture() -> void:
	var source := MapSource.new(
		"myranth",
		"res://../../content/maps/myranth/map.json",
		"res://../../assets/runtime/maps/myranth",
		"content",
	)
	var result: Dictionary = _open_map().execute(source)
	_check(
		result["ok"],
		"canonical content map opens with compiled runtime art: %s"
		% result.get("message", "unknown error"),
	)
	if not result["ok"]:
		return
	var document = result["document"]
	var reference_texture: Texture2D = result["reference_texture"]
	_check(document.map_id() == "myranth", "map identity is retained")
	_check(document.tiles().size() == 475, "complete map is normalized")
	_check(document.tiles().is_read_only(), "tile collection is immutable")
	_check(result["missing_tiles"].is_empty(), "all runtime texture pages exist")
	_check(result["invalid_tiles"].is_empty(), "all runtime texture pages decode")
	_check(reference_texture.get_width() > 0, "reference atlas is created")

	var meshes := MeshBuilder.new().build(
		document,
		result["terrain_texture"],
		reference_texture,
		RenderSettings.new(),
	)
	_check(meshes["terrain_mesh"].get_surface_count() == 1, "runtime terrain mesh is built")
	_check(meshes["reference_mesh"].get_surface_count() == 1, "runtime reference mesh is built")
	_check(meshes["grid_mesh"].get_surface_count() == 1, "runtime grid overlay is built")

func _test_catalog() -> void:
	var sources := MapAssetCatalog.new().discover()
	var identifiers: Array[String] = []
	for source in sources:
		identifiers.append(source.map_id)
	_check("myranth" in identifiers, "catalog discovers canonical content maps")
	_check("aonw2_starter" in identifiers, "catalog discovers versioned Godot maps")
	for source in sources:
		if source.map_id == "aonw2_starter":
			_check(source.origin == "content", "canonical content wins duplicate map ids")
			_check(
				source.visual_directory == "res://assets/maps/aonw2_starter",
				"starter uses the generated Godot visual bundle",
			)

func _test_every_catalog_bundle_matches_map() -> void:
	var map_repository := JsonMapRepository.new()
	var atlas_repository := TileAtlasRepository.new()
	for source in MapAssetCatalog.new().discover():
		var map_result: Dictionary = map_repository.load_map(source)
		_check(map_result["ok"], "%s canonical map opens" % source.map_id)
		if not map_result["ok"]:
			continue
		var manifest_path := ProjectSettings.globalize_path(
			source.visual_directory.path_join("map_texture_manifest.json")
		)
		var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
		_check(manifest_file != null, "%s asset bundle exists" % source.map_id)
		if manifest_file == null:
			continue
		var manifest: Variant = JSON.parse_string(manifest_file.get_as_text())
		_check(
			atlas_repository._manifest_error(manifest, map_result["document"]).is_empty(),
			"%s asset bundle matches its Rust map content hash" % source.map_id,
		)

func _open_map() -> AonwOpenMap:
	return OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new())

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

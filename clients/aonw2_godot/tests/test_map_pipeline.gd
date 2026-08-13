extends SceneTree

const GenerateGodotMap := preload("res://application/map/generate_godot_map.gd")
const MapSource := preload("res://application/map/map_source.gd")
const OpenMap := preload("res://application/map/open_map.gd")
const MapDocument := preload("res://domain/map/map_document.gd")
const MeshBuilder := preload("res://presentation/map/map_surface_mesh_builder.gd")
const HexGridGeometry := preload("res://domain/map/hex_grid_geometry.gd")
const HexMapProjection := preload("res://presentation/map/hex_map_projection.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const MapAssetCatalog := preload("res://infrastructure/map/map_asset_catalog.gd")
const GodotMapSceneRepository := preload("res://infrastructure/map/godot_map_scene_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")
const NativeEngineBridge := preload("res://infrastructure/engine/native_engine_bridge.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_geometry()
	_test_map_projection()
	_test_strict_document_boundary()
	_test_native_engine_boundary()
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
		"res://.godot/map_generation_test/generated",
	)
	var scene_path := scene_repository.scene_path_for("aonw2_starter")
	if FileAccess.file_exists(scene_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scene_path))
	var generator := GenerateGodotMap.new(_open_map(), scene_repository)
	var result := generator.execute(source, {
		"height_step": 0.2,
		"reference_opacity": 0.45,
		"grid_visible": true,
	})
	_check(result["ok"], "starter map is saved as a self-contained Godot scene")
	if not result["ok"]:
		return
	_check(ResourceLoader.exists(scene_path), "generated Godot scene exists")
	_check(
		ResourceLoader.exists(scene_repository.generated_scene_path_for("aonw2_starter")),
		"generated surface scene exists independently",
	)
	_check(result["authored_scene_created"], "authored scene is created on first generation")
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
	var authored_root := packed.instantiate() as Node3D
	var instance := authored_root.find_child("AonwMap3D", true, false) as AonwMapSurface
	_check(instance != null, "authored scene owns an Aonw map surface")
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
		var manual_child := Node3D.new()
		manual_child.name = "ManualModel"
		authored_root.add_child(manual_child)
		manual_child.owner = authored_root
		var surface_child := Node3D.new()
		surface_child.name = "SurfaceModel"
		instance.add_child(surface_child)
		surface_child.owner = authored_root
		var authored_with_manual_child := PackedScene.new()
		_check(
			authored_with_manual_child.pack(authored_root) == OK
			and ResourceSaver.save(authored_with_manual_child, scene_path) == OK,
			"authored scene accepts manual children",
		)
	authored_root.free()

	var regenerated := generator.execute(source, {"height_step": 0.3})
	_check(regenerated["ok"], "generated surface can be refreshed")
	if not regenerated["ok"]:
		return
	_check(not regenerated["authored_scene_created"], "regeneration preserves authored scene")
	var preserved_scene := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	var preserved_root := preserved_scene.instantiate()
	var refreshed_surface := preserved_root.find_child(
		"AonwMap3D",
		true,
		false,
	) as AonwMapSurface
	_check(
		preserved_root.find_child("ManualModel", true, false) != null,
		"regeneration preserves manual authored children",
	)
	_check(
		refreshed_surface != null and is_equal_approx(refreshed_surface.height_step, 0.3),
		"authored scene resolves the refreshed generated surface",
	)
	_check(
		refreshed_surface != null
		and refreshed_surface.find_child("SurfaceModel", true, false) != null,
		"regeneration preserves authored children attached to the surface",
	)
	preserved_root.free()

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

func _test_native_engine_boundary() -> void:
	var bridge := NativeEngineBridge.new()
	_check(bridge.is_available(), "Rust GDExtension is loaded")
	if not bridge.is_available():
		return
	var file := FileAccess.open(
		"res://assets/maps/aonw2_starter/map.json",
		FileAccess.READ,
	)
	_check(file != null, "native boundary fixture map opens")
	if file == null:
		return
	var map_json := file.get_as_text()
	var validation := bridge.validate_map_json(map_json, false)
	_check(validation["ok"] and validation["native"], "Rust validates the strict map")
	_check(
		validation.get("value", {}).get("contentHash", "").length() == 64,
		"Rust returns the logical content hash",
	)

	var session: Object = ClassDB.instantiate("AonwLocalSession")
	_check(session != null, "native local session is registered")
	if session == null:
		return
	var state_json := JSON.stringify({
		"schemaVersion": 1,
		"revision": 7,
		"turn": 2,
		"units": [{
			"id": "ship-1",
			"ownerPlayerId": "player-1",
			"kind": "scoutShip",
			"col": 0,
			"row": 0,
			"movementUnits": 4,
			"posture": "active",
			"movementBlocked": false,
			"queuedPath": null,
			"carriedArtifactId": null,
		}],
	})
	var opened: Dictionary = JSON.parse_string(session.open(
		map_json,
		false,
		state_json,
		"player-1",
		"",
	))
	_check(opened["ok"], "native local movement session opens")
	var reachable: Dictionary = JSON.parse_string(session.reachable_json("ship-1", 7))
	_check(
		reachable["ok"] and not reachable["value"]["tiles"].is_empty(),
		"native session returns reachable hexes",
	)
	var moved: Dictionary = JSON.parse_string(session.move_unit_json("ship-1", 1, 0, 7))
	_check(
		moved["ok"]
		and moved["value"]["revision"] == 8
		and moved["value"]["event"]["toCol"] == 1,
		"native session applies a revision-bound move",
	)

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

func _test_map_projection() -> void:
	var result := _open_map().execute(MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		AonwMapSource.Format.VERSIONED,
		"Godot",
	))
	_check(result["ok"], "projection fixture map opens")
	if not result["ok"]:
		return
	var document: AonwMapDocument = result["document"]
	var projection := HexMapProjection.new(document, 1.0, 0.16)
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
	_check(
		projection.ray_to_hex(Vector3.ZERO, Vector3.RIGHT) == HexMapProjection.INVALID_HEX,
		"parallel ray does not select a hex",
	)

func _open_map() -> AonwOpenMap:
	return OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new())

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

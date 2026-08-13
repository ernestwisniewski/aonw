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
const RenderSettings := preload("res://presentation/map/map_render_settings.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_geometry()
	_test_map_projection()
	_test_strict_document_boundary()
	_test_native_engine_boundary()
	_test_catalog()
	_test_canonical_map_with_reference_art()
	_test_generated_godot_scene()

	if _failures.is_empty():
		print("map pipeline: OK")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _test_canonical_map_with_reference_art() -> void:
	var source := MapSource.new(
		"myranth",
		"res://../../content/maps/myranth/map.json",
		"res://../../assets/maps/myranth",
		"content",
	)
	var result := _open_map().execute(source)
	_check(result["ok"], "canonical content map opens with separate reference art")
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
		RenderSettings.new(),
	)
	var terrain: ArrayMesh = meshes["terrain_mesh"]
	var reference: ArrayMesh = meshes["reference_mesh"]
	var grid: ArrayMesh = meshes["grid_mesh"]
	_check(terrain.get_surface_count() == 1, "terrain mesh is built")
	_check(reference.get_surface_count() == 1, "reference mesh is built")
	_check(grid.get_surface_count() == 1, "grid overlay is built")
	_check(
		grid.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES,
		"grid uses visible geometry instead of one-pixel line primitives",
	)
	var grid_material := grid.surface_get_material(0) as StandardMaterial3D
	_check(
		grid_material != null
		and grid_material.render_priority > 0
		and grid_material.no_depth_test,
		"grid renders after the reference texture",
	)
	_check(
		terrain.surface_get_array_index_len(0) == document.tiles().size() * 18,
		"terrain contains six triangles per hex",
	)

func _test_generated_godot_scene() -> void:
	var source := MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
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
		"grid_opacity": 0.35,
		"grid_width": 0.06,
	})
	_check(result["ok"], "starter map is saved as a self-contained Godot scene")
	if not result["ok"]:
		return
	_check(ResourceLoader.exists(scene_path), "generated Godot scene exists")
	_check(
		ResourceLoader.exists(result["generated_scene_path"]),
		"generated surface scene exists independently",
	)
	_check(result["authored_scene_created"], "authored scene is created on first generation")
	_check(
		FileAccess.file_exists(result["reference_texture_path"]),
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
			is_equal_approx(instance.render_settings.reference_opacity, 0.45),
			"reference opacity is persisted",
		)
		_check(instance.render_settings.grid_visible, "hex grid visibility is persisted")
		_check(
			is_equal_approx(instance.render_settings.grid_opacity, 0.35),
			"hex grid opacity is persisted",
		)
		_check(
			is_equal_approx(instance.render_settings.grid_width, 0.06),
			"hex grid width is persisted",
		)
		instance.set_grid_visible(false)
		_check(not instance.get_node("HexGrid").visible, "hex grid updates in the editor scene")
		instance.set_grid_visible(true)
		instance.set_grid_opacity(0.2)
		var grid_material := instance.get_node("HexGrid").material_override as StandardMaterial3D
		_check(
			grid_material != null and is_equal_approx(grid_material.albedo_color.a, 0.2),
			"hex grid opacity updates without regenerating the scene",
		)
		_check(instance.terrain_mesh() != null, "generated scene retains terrain mesh")
		_check(instance.reference_mesh() != null, "generated scene retains reference texture mesh")
		_check(instance.grid_mesh() != null, "generated scene retains grid mesh")
		var opened := _open_map().execute(source)
		_check(opened["ok"], "generated surface editing context reloads")
		if opened["ok"]:
			instance.present(
				opened["document"],
				opened["terrain_texture"],
				opened["reference_texture"],
			)
			instance.set_geometry(0.42, 0.08)
			var edited_bounds := instance.terrain_mesh().get_aabb()
			var persisted := scene_repository.persist_surface_geometry(instance)
			_check(persisted["ok"], "edited geometry resources are persisted")
			_check(
				instance.render_settings.resource_path.get_base_dir().get_file()
				== persisted["generation_id"],
				"render settings and meshes share one immutable generation",
			)
			for mesh in [
				instance.terrain_mesh(),
				instance.reference_mesh(),
				instance.grid_mesh(),
			]:
				_check(
					mesh.resource_path.get_base_dir().get_file()
					== persisted["generation_id"],
					"persisted meshes share one immutable generation",
				)
			var before_publish := ResourceLoader.load(
				scene_path,
				"PackedScene",
				ResourceLoader.CACHE_MODE_REPLACE_DEEP,
			) as PackedScene
			var before_publish_root := before_publish.instantiate()
			var before_publish_surface := before_publish_root.find_child(
				"AonwMap3D", true, false
			) as AonwMapSurface
			_check(
				is_equal_approx(before_publish_surface.render_settings.height_step, 0.2),
				"staging a generation does not mutate the published scene",
			)
			before_publish_root.free()
			var staged_manifest_file := FileAccess.open(
				"res://.godot/map_generation_test/assets/aonw2_starter/manifest.json",
				FileAccess.READ,
			)
			var staged_manifest: Dictionary = JSON.parse_string(
				staged_manifest_file.get_as_text()
			)
			_check(
				staged_manifest["activeGeneration"] != persisted["generation_id"],
				"staging does not publish the generation before the scene is saved",
			)
			var edited_scene := PackedScene.new()
			_check(
				edited_scene.pack(authored_root) == OK
				and ResourceSaver.save(edited_scene, scene_path) == OK,
				"edited render settings are saved with the authored scene",
			)
			_check(
				scene_repository.publish_surface_geometry(instance)["ok"],
				"saved geometry generation is published in the manifest",
			)
			var manifest_file := FileAccess.open(
				"res://.godot/map_generation_test/assets/aonw2_starter/manifest.json",
				FileAccess.READ,
			)
			var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
			_check(
				manifest["activeGeneration"] == persisted["generation_id"],
				"manifest publishes the saved geometry generation",
			)
			var reloaded_scene := ResourceLoader.load(
				scene_path,
				"PackedScene",
				ResourceLoader.CACHE_MODE_REPLACE_DEEP,
			) as PackedScene
			var reloaded_root := reloaded_scene.instantiate()
			var reloaded_surface := reloaded_root.find_child(
				"AonwMap3D", true, false
			) as AonwMapSurface
			var reloaded_bounds := reloaded_surface.terrain_mesh().get_aabb()
			_check(
				is_equal_approx(reloaded_surface.render_settings.height_step, 0.42),
				"edit-save-reload keeps the height step",
			)
			_check(
				is_equal_approx(reloaded_surface.render_settings.grid_width, 0.08),
				"edit-save-reload keeps the grid width",
			)
			_check(
				reloaded_bounds.position.is_equal_approx(edited_bounds.position),
				"edit-save-reload keeps the terrain bounds position",
			)
			_check(
				reloaded_bounds.size.is_equal_approx(edited_bounds.size),
				"edit-save-reload keeps the terrain bounds size: %s != %s"
				% [reloaded_bounds.size, edited_bounds.size],
			)
			reloaded_root.free()
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
		refreshed_surface != null
		and is_equal_approx(refreshed_surface.render_settings.height_step, 0.3),
		"authored scene resolves the refreshed generated surface",
	)
	_check(
		refreshed_surface != null
		and refreshed_surface.find_child("SurfaceModel", true, false) != null,
		"regeneration preserves authored children attached to the surface",
	)
	preserved_root.free()

func _test_strict_document_boundary() -> void:
	var file := FileAccess.open(
		"res://assets/maps/aonw2_starter/map.json",
		FileAccess.READ,
	)
	_check(file != null, "content identifier fixture map opens")
	if file != null:
		var fixture: Dictionary = JSON.parse_string(file.get_as_text())
		for valid_identifier in ["a", "a_b-1", "aonw2_starter"]:
			var valid_map := fixture.duplicate(true)
			valid_map["mapName"] = valid_identifier
			var valid_result := NativeEngineBridge.new().validate_map_json(
				JSON.stringify(valid_map)
			)
			_check(
				valid_result["ok"],
				"lowercase ASCII content identifiers are accepted: %s" % valid_result,
			)
		for invalid_identifier in ["", "Uppercase", "ends_", "żagle"]:
			var invalid_map := fixture.duplicate(true)
			invalid_map["mapName"] = invalid_identifier
			_check(
				not NativeEngineBridge.new().validate_map_json(JSON.stringify(invalid_map))["ok"],
				"invalid content identifiers are rejected",
			)
		var feature_first := fixture.duplicate(true)
		feature_first["tiles"][0]["terrains"] = ["forest"]
		_check(
			not NativeEngineBridge.new().validate_map_json(JSON.stringify(feature_first))["ok"],
			"tiles require an explicit primary terrain",
		)
		var mismatched_source := MapSource.new(
			"wrong_map_id",
			"res://assets/maps/aonw2_starter/map.json",
			"res://assets/maps/aonw2_starter",
			"test",
		)
		_check(
			not JsonMapRepository.new().load_map(mismatched_source)["ok"],
			"source directory id must match mapName",
		)
	var raw := {
		"schemaVersion": 1,
		"gridLayout": "oddQFlatTop",
		"cols": 5,
		"rows": 5,
		"mapName": "strict_test",
		"objectives": [],
		"tiles": [],
	}
	var strict_result := NativeEngineBridge.new().validate_map_json(JSON.stringify(raw))
	_check(not strict_result["ok"], "strict documents require defaultZoom")

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
	var validation := bridge.validate_map_json(map_json)
	_check(validation["ok"] and validation["native"], "Rust validates the strict map")
	_check(
		validation.get("value", {}).get("contentHash", "").length() == 64,
		"Rust returns the logical content hash",
	)

	var session: Object = ClassDB.instantiate("AonwLocalSession")
	_check(session != null, "native local session is registered")
	if session == null:
		return
	var scenario_file := FileAccess.open(
		"res://assets/scenarios/aonw2_starter.json",
		FileAccess.READ,
	)
	_check(scenario_file != null, "native boundary scenario opens")
	if scenario_file == null:
		return
	var opened: Dictionary = JSON.parse_string(session.open(
		map_json,
		scenario_file.get_as_text(),
		"preview-player",
	))
	_check(opened["ok"], "native local scenario session opens")
	var snapshot: Dictionary = JSON.parse_string(session.snapshot_json())
	_check(
		snapshot["ok"] and snapshot["value"]["units"].size() == 1,
		"native snapshot owns the scenario unit view",
	)
	var reachable: Dictionary = JSON.parse_string(
		session.reachable_json("preview-commander", 0),
	)
	_check(
		reachable["ok"] and not reachable["value"]["tiles"].is_empty(),
		"native session returns reachable hexes",
	)
	var route: Dictionary = JSON.parse_string(
		session.route_plan_json("preview-commander", 2, 2, 0),
	)
	_check(route["ok"] and route["value"]["steps"].size() > 1, "native route is planned")
	var moved: Dictionary = JSON.parse_string(
		session.move_unit_json("preview-commander", 2, 2, 0),
	)
	_check(
		moved["ok"]
		and moved["value"]["accepted"]
		and moved["value"]["revision"] == 1
		and moved["value"]["evidence"]["steps"][-1]["row"] == 2,
			"native session applies a revision-bound move",
		)
	var skipped: Dictionary = JSON.parse_string(
		session.skip_unit_turn_json("preview-commander", 1),
	)
	_check(
		skipped["ok"]
		and skipped["value"]["accepted"]
		and skipped["value"]["revision"] == 2
		and skipped["value"]["viewPatch"]["upsertedUnits"][0]["movementUnits"] == 0,
		"native session skips a unit turn",
	)
	var cancelled: Dictionary = JSON.parse_string(
		session.cancel_unit_action_json("preview-commander", 2),
	)
	_check(
		cancelled["ok"]
		and cancelled["value"]["accepted"]
		and cancelled["value"]["revision"] == 3,
		"native session cancels a unit action",
	)
	var fortified: Dictionary = JSON.parse_string(
		session.fortify_unit_json("preview-commander", 3),
	)
	_check(
		fortified["ok"]
		and fortified["value"]["accepted"]
		and fortified["value"]["revision"] == 4
		and fortified["value"]["viewPatch"]["upsertedUnits"][0]["posture"] == "fortified",
		"native session fortifies an idle unit",
	)
	var saved: Dictionary = JSON.parse_string(session.save_game_json())
	_check(
		saved["ok"] and not saved["value"]["document"].is_empty(),
		"native session exports a canonical save",
	)
	var replay: Dictionary = JSON.parse_string(session.replay_log_json())
	_check(
		replay["ok"] and not replay["value"]["document"].is_empty(),
		"native session exports a deterministic replay",
	)
	var verified: Dictionary = JSON.parse_string(session.verify_replay(
		map_json,
		replay["value"]["document"],
	))
	_check(
		verified["ok"] and verified["value"]["entryCount"] == 4,
		"native session verifies replay results in Rust",
	)
	session.close()
	var restored: Dictionary = JSON.parse_string(session.open_save(
		map_json,
		saved["value"]["document"],
	))
	_check(
		restored["ok"] and restored["value"]["revision"] == 4,
		"native session restores a canonical save",
	)

func _test_catalog() -> void:
	var sources := MapAssetCatalog.new().discover()
	var identifiers: Array[String] = []
	for source in sources:
		identifiers.append(source.map_id)
	_check("myranth" in identifiers, "catalog discovers maps from root assets")
	_check("aonw2_starter" in identifiers, "catalog discovers versioned Godot maps")
	for source in sources:
		if source.map_id == "aonw2_starter":
			_check(source.origin == "content", "canonical content wins duplicate map ids")

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

func _open_map() -> AonwOpenMap:
	return OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new())

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

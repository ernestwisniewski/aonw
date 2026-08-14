extends RefCounted

const GenerateGodotMap := preload("res://application/map/generate_godot_map.gd")
const MapSource := preload("res://application/map/map_source.gd")
const OpenMap := preload("res://application/map/open_map.gd")
const MeshBuilder := preload("res://presentation/map/map_surface_mesh_builder.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const MapAssetCatalog := preload("res://infrastructure/map/map_asset_catalog.gd")
const GodotMapSceneRepository := preload("res://infrastructure/map/godot_map_scene_repository.gd")
const TileAtlasRepository := preload("res://infrastructure/map/tile_atlas_repository.gd")
const RenderSettings := preload("res://presentation/map/map_render_settings.gd")

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_catalog()
	_test_canonical_map_with_reference_art()
	_test_generated_godot_scene()

func _test_canonical_map_with_reference_art() -> void:
	var source := MapSource.new(
		"myranth",
		"res://../../content/maps/myranth/map.json",
		"res://../../assets/maps/myranth",
		"content",
	)
	var result: Dictionary = _open_map().execute(source)
	_check(result["ok"], "canonical content map opens with separate reference art")
	if not result["ok"]:
		return
	var document = result["document"]
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
	_check(
		atlas.get_pixelv(center).get_luminance() > 0.05,
		"reference atlas contains source imagery",
	)

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
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as PackedScene
	_check(packed != null, "generated Godot scene loads")
	if packed == null:
		return
	var authored_root := packed.instantiate() as Node3D
	var instance = authored_root.find_child("AonwMap3D", true, false)
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
		var opened: Dictionary = _open_map().execute(source)
		_check(opened["ok"], "generated surface editing context reloads")
		if opened["ok"]:
			instance.present(
				opened["document"],
				opened["terrain_texture"],
				opened["reference_texture"],
			)
			instance.set_geometry(0.42, 0.08)
			var edited_bounds = instance.terrain_mesh().get_aabb()
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
			)
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
			var reloaded_surface := reloaded_root.find_child("AonwMap3D", true, false)
			var reloaded_bounds = reloaded_surface.terrain_mesh().get_aabb()
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
	var refreshed_surface := preserved_root.find_child("AonwMap3D", true, false)
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

func _open_map():
	return OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new())

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

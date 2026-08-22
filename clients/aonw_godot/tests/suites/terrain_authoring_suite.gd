extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const OpenMap := preload("res://game/application/map/open_map.gd")
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const TileAtlasRepository := preload("res://game/infrastructure/map/tile_atlas_repository.gd")
const ArtifactRepository := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const SceneRepository := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_scene_repository.gd"
)
const GenerateTerrainAuthoringMap := preload(
	"res://editor/map_authoring/application/generate_terrain_authoring_map.gd"
)

var _failures: Array[String]
var _test_root: String
var _camera: Camera3D

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_root = "res://.godot/terrain_authoring_test/%s" % OS.get_process_id()
	_camera = Camera3D.new()
	_camera.position = Vector3(40.0, 100.0, 40.0)
	Engine.get_main_loop().root.add_child(_camera)
	var generation := _generate_scene()
	_check(generation["ok"], "Terrain3D authoring scene is generated")
	if generation["ok"]:
		await _test_authoring_session(generation["scene_path"])
	_camera.free()

func _generate_scene() -> Dictionary:
	var source := MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	)
	var scene_repository := SceneRepository.new(
		_test_root.path_join("scenes"),
		_test_root.path_join("assets"),
		"res://.godot/terrain_compiled",
	)
	var generator := GenerateTerrainAuthoringMap.new(
		OpenMap.new(JsonMapRepository.new(), TileAtlasRepository.new()),
		ArtifactRepository.new(),
		scene_repository,
	)
	var result := generator.execute(source)
	if result["ok"]:
		_check(result["scene_created"], "Terrain3D authoring scene is created once")
		var regenerated := generator.execute(source)
		_check(
			regenerated["ok"] and not regenerated["scene_created"],
			"regeneration preserves the existing authored scene",
		)
	return result

func _test_authoring_session(scene_path: String) -> void:
	var opened := await _open_surface(scene_path)
	_check(opened["ok"], "Terrain3D authoring session opens")
	if not opened["ok"]:
		return
	var root: Node = opened["root"]
	var surface: AonwTerrainAuthoringSurface = opened["surface"]
	var artifact := surface.artifact()
	_check(surface.terrain() is Terrain3D, "authoring backend is Terrain3D")
	_check(
		surface.find_child("BaseTerrain", true, false) == null,
		"authoring scene has no alternative mesh terrain backend",
	)
	_check(
		surface.map_content_hash == artifact.map_content_hash
		and surface.authoring_profile_hash == artifact.authoring_profile_hash
		and surface.generated_base_hash == artifact.generated_base_hash,
		"authoring scene exposes exact compiled metadata",
	)

	var sample := Vector2i(20, 20)
	_check_approx(
		surface.height_at(sample),
		artifact.base_image.get_pixelv(sample).r,
		"Terrain3D imports the generated base raster",
	)
	_test_overlay_alignment(surface, artifact)
	_test_overlay_controls(surface, artifact)
	_test_regional_clamp_and_publish(surface, artifact)
	_test_undo_redo(surface, artifact)

	var manual_pixel := Vector2i(30, 30)
	var manual_height := artifact.maximum_at(manual_pixel) - 0.25
	surface.set_height(manual_pixel, manual_height)
	var revision_before_save := surface.terrain_revision
	var save_result := surface.save_draft()
	_check(save_result["ok"], "manual Terrain3D final is saved as a draft")
	var refresh_result := surface.refresh_generated_artifact()
	_check(
		refresh_result["ok"] and refresh_result["manual_final_preserved"],
		"generated base refresh explicitly preserves manual final terrain",
	)
	_check_approx(
		surface.height_at(manual_pixel),
		manual_height,
		"generated base refresh does not overwrite manual sculpting",
	)
	var publish_result := surface.publish()
	_check(publish_result["ok"], "valid Terrain3D final is published")
	if publish_result["ok"]:
		_test_publish_manifest(publish_result["manifest_path"], surface)
	root.queue_free()
	await Engine.get_main_loop().process_frame

	var reopened := await _open_surface(scene_path)
	_check(reopened["ok"], "saved Terrain3D authoring session reopens")
	if reopened["ok"]:
		var reopened_surface: AonwTerrainAuthoringSurface = reopened["surface"]
		_check_approx(
			reopened_surface.height_at(manual_pixel),
			manual_height,
			"manual sculpting survives close and reopen",
		)
		_check(
			reopened_surface.terrain_revision == revision_before_save,
			"terrainRevision survives close and reopen",
		)
		reopened["root"].queue_free()
		await Engine.get_main_loop().process_frame

func _test_regional_clamp_and_publish(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var first := Vector2i(10, 10)
	var second := Vector2i(20, 10)
	surface.terrain().data.set_height(
		artifact.local_position(first),
		artifact.maximum_at(first) + 50.0,
	)
	surface.terrain().data.set_height(
		artifact.local_position(second),
		artifact.maximum_at(second) + 50.0,
	)
	var revision_before_edit := surface.terrain_revision
	surface.terrain().data.maps_edited.emit(AABB(
		artifact.local_position(first),
		Vector3(
			artifact.sample_spacing_meters,
			1.0,
			artifact.sample_spacing_meters,
		),
	))
	_check(
		surface.terrain_revision > revision_before_edit,
		"Terrain3D maps_edited triggers the regional authoring transaction",
	)
	_check_approx(
		surface.height_at(first),
		artifact.maximum_at(first),
		"regional clamp enforces the local maximum",
	)
	_check(
		surface.height_at(second) > artifact.maximum_at(second),
		"regional clamp does not scan or mutate an untouched pixel",
	)
	var blocked := surface.publish()
	_check(
		not blocked["ok"] and blocked.has("validation"),
		"independent full validator blocks an invalid publish",
	)
	surface.clamp_changed_region(Rect2i(second, Vector2i.ONE))
	_check(surface.validate_for_publish()["ok"], "full validator accepts the clamped terrain")

func _test_undo_redo(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var pixel := Vector2i(25, 25)
	var previous := surface.height_at(pixel)
	var requested := artifact.maximum_at(pixel) - 0.5
	var history := UndoRedo.new()
	_check(
		surface.change_height(history, pixel, requested),
		"Terrain3D height edit records an undoable action",
	)
	_check_approx(surface.height_at(pixel), requested, "Terrain3D edit is applied")
	history.undo()
	_check_approx(surface.height_at(pixel), previous, "Terrain3D edit is undone")
	history.redo()
	_check_approx(surface.height_at(pixel), requested, "Terrain3D edit is redone")
	history.clear_history(false)
	history.free()

func _test_overlay_controls(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	surface.set_reference_visible(false)
	_check(not surface.get_node("ReferenceTexture").visible, "reference can be hidden")
	surface.set_reference_visible(true)
	surface.set_reference_opacity(0.4)
	var reference_material := (
		surface.get_node("ReferenceTexture").mesh.surface_get_material(0)
		as StandardMaterial3D
	)
	_check_approx(reference_material.albedo_color.a, 0.4, "reference opacity is editable")
	surface.set_grid_visible(false)
	_check(not surface.get_node("HexGrid").visible, "debug grid can be hidden")
	surface.set_grid_visible(true)
	surface.set_constraints_visible(true)
	_check(
		surface.get_node("MinimumHeightDebug").visible
		and surface.get_node("MaximumHeightDebug").visible,
		"min and max debug envelopes can be shown",
	)
	var marker := surface.get_node("CityCoreMarker")
	_check(marker.mesh is CylinderMesh, "city-core scale marker is visible geometry")
	_check(
		marker.mesh.top_radius <= artifact.hex_radius_meters,
		"city-core marker fits within one authoring hex",
	)

func _test_overlay_alignment(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var pixel := Vector2i(artifact.width / 2, artifact.height / 2)
	var index := pixel.y * artifact.width + pixel.x
	var reference := surface.get_node("ReferenceTexture") as MeshInstance3D
	var reference_arrays := reference.mesh.surface_get_arrays(0)
	var reference_vertex: Vector3 = reference_arrays[Mesh.ARRAY_VERTEX][index]
	var transformed := reference.transform * reference_vertex
	_check(
		absf(
			transformed.y
			- surface.terrain().data.get_height(Vector3(transformed.x, 0.0, transformed.z))
		) <= 0.08,
		"reference mesh follows Terrain3D within overlay tolerance",
	)

	var grid := surface.get_node("HexGrid") as MeshInstance3D
	var grid_vertices: PackedVector3Array = grid.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var aligned_grid_vertex := false
	for vertex in grid_vertices:
		var terrain_height := surface.terrain().data.get_height(Vector3(vertex.x, 0.0, vertex.z))
		if not is_finite(terrain_height):
			continue
		if absf(vertex.y - terrain_height) <= 0.2:
			aligned_grid_vertex = true
			break
	_check(aligned_grid_vertex, "debug grid follows Terrain3D within overlay tolerance")

func _test_publish_manifest(path: String, surface: AonwTerrainAuthoringSurface) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "published terrain manifest exists")
	if file == null:
		return
	var manifest: Dictionary = JSON.parse_string(file.get_as_text())
	_check(
		manifest["mapContentHash"] == surface.map_content_hash
		and manifest["authoringProfileHash"] == surface.authoring_profile_hash
		and manifest["generatedBaseHash"] == surface.generated_base_hash
		and int(manifest["terrainRevision"]) == surface.terrain_revision,
		"published terrain records all required identities and terrainRevision",
	)

func _open_surface(scene_path: String) -> Dictionary:
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if packed == null:
		return {"ok": false, "message": "authoring scene does not load"}
	var root := packed.instantiate()
	var surface := root.find_child("TerrainAuthoring", true, false) as AonwTerrainAuthoringSurface
	if surface == null:
		root.free()
		return {"ok": false, "message": "authoring surface is missing"}
	Engine.get_main_loop().root.add_child(root)
	surface.terrain().set_camera(_camera)
	var open_result: Dictionary = await surface.session_opened
	await Engine.get_main_loop().process_frame
	if not open_result["ok"]:
		root.free()
		return open_result
	return {"ok": true, "root": root, "surface": surface}

func _check_approx(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) <= 0.001, "%s (%s != %s)" % [message, actual, expected])

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

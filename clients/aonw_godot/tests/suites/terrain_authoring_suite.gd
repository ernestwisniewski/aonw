extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const AuthoringStore := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_store.gd"
)
const CompositionRoot := preload(
	"res://editor/map_authoring/composition/map_authoring_composition_root.gd"
)
const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)
const AuthoringSession := preload(
	"res://editor/map_authoring/application/terrain_authoring_session.gd"
)
const MemoryPersistence := preload(
	"res://tests/doubles/memory_terrain_authoring_persistence.gd"
)

var _failures: Array[String]
var _test_root: String
var _camera: Camera3D
var _composition: AonwMapAuthoringCompositionRoot

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_root = "res://.godot/terrain_authoring_test/%s" % OS.get_process_id()
	_composition = CompositionRoot.new(
		_test_root.path_join("scenes"),
		_test_root.path_join("assets"),
		"res://.godot/terrain_compiled",
	)
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
	var generator := _composition.generator()
	var result := generator.execute(source)
	if result["ok"]:
		_check(result["scene_created"], "Terrain3D authoring scene is created once")
		_add_authored_child(result["scene_path"])
		var regenerated := generator.execute(source)
		_check(
			regenerated["ok"] and not regenerated["scene_created"],
			"regeneration preserves the existing authored scene",
		)
		_check(
			_scene_has_authored_child(result["scene_path"]),
			"regeneration preserves manually authored children",
		)
	return result

func _add_authored_child(scene_path: String) -> void:
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	_check(packed != null, "generated authoring scene can be loaded for manual editing")
	if packed == null:
		return
	var root := packed.instantiate()
	var authored := Node3D.new()
	authored.name = "AuthoredLandmark"
	root.add_child(authored)
	authored.owner = root
	var updated := PackedScene.new()
	var error := updated.pack(root)
	if error == OK:
		error = ResourceSaver.save(updated, scene_path)
	_check(error == OK, "manual authored child can be saved")
	root.free()

func _scene_has_authored_child(scene_path: String) -> bool:
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	var found := root.find_child("AuthoredLandmark", true, false) != null
	root.free()
	return found

func _test_authoring_session(scene_path: String) -> void:
	var opened := await _open_surface(scene_path)
	_check(opened["ok"], "Terrain3D authoring session opens")
	if not opened["ok"]:
		return
	var root: Node = opened["root"]
	var surface: AonwTerrainAuthoringSurface = opened["surface"]
	var artifact := surface.artifact()
	await _test_persistence_port(artifact)
	_check(surface.terrain() is Terrain3D, "authoring backend is Terrain3D")
	_check(
		surface.generated_world().name == "GeneratedWorld"
		and surface.manual_world().name == "ManualWorld"
		and surface.generated_world() != surface.manual_world(),
		"generated and manual world objects have separate scene lifecycles",
	)
	_check_approx(
		float(artifact.max_city_slope),
		0.35,
		"compiled maxCitySlope is retained as reserved authoring metadata",
	)
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
	_check(
		surface.get_node("MinimumHeightDebug").mesh == null
		and surface.get_node("MaximumHeightDebug").mesh == null,
		"constraint overlays are lazy while hidden",
	)
	_test_overlay_controls(surface, artifact)
	await _test_incremental_overlay_refresh(surface, artifact)
	_test_regional_clamp_and_publish(surface, artifact)
	_test_undo_redo(surface, artifact)

	var manual_pixel := Vector2i(30, 30)
	var manual_height := artifact.maximum_at(manual_pixel) - 0.25
	surface.set_height(manual_pixel, manual_height)
	var revision_before_save := surface.terrain_revision
	var save_result := surface.save_draft()
	_check(
		save_result["ok"],
		"manual Terrain3D final is saved as a draft: %s" % save_result.get("message", ""),
	)
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
	_check(
		publish_result["ok"],
		"valid Terrain3D final is published: %s" % publish_result.get("message", ""),
	)
	if publish_result["ok"]:
		_test_publish_manifest(publish_result["manifest_path"], surface)
		_test_artifact_identity(surface, artifact)
		var published_files := _directory_hashes(publish_result["data_directory"])
		var published_pointer_hash := FileAccess.get_sha256(publish_result["manifest_path"])
		manual_height = artifact.maximum_at(manual_pixel) - 0.75
		surface.set_height(manual_pixel, manual_height)
		revision_before_save = surface.terrain_revision
		var next_draft := surface.save_draft()
		_check(next_draft["ok"], "a newer Terrain3D draft can be saved after publish")
		if next_draft["ok"]:
			_check(
				next_draft["data_directory"] != publish_result["data_directory"],
				"draft and published terrain use separate immutable snapshots",
			)
			_check(
				_directory_hashes(publish_result["data_directory"]) == published_files,
				"saving revision N+1 leaves published revision N byte-for-byte unchanged",
			)
			_check(
				FileAccess.get_sha256(publish_result["manifest_path"])
				== published_pointer_hash,
				"saving a draft does not move the published terrain pointer",
			)
			_test_snapshot_integrity(surface, artifact, next_draft["data_directory"])
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

func _test_persistence_port(artifact: AonwTerrainCompiledArtifact) -> void:
	var terrain := Terrain3D.new()
	Engine.get_main_loop().root.add_child(terrain)
	await Engine.get_main_loop().process_frame
	terrain.vertex_spacing = artifact.sample_spacing_meters
	var persistence := MemoryPersistence.new()
	var session := AuthoringSession.new(terrain.data, artifact, persistence)
	var open_result := session.open()
	_check(open_result["ok"], "authoring session opens through its persistence port")
	if open_result["ok"]:
		_check(
			persistence.load_count == 1
			and persistence.last_identity.to_dictionary()
			== artifact.identity().to_dictionary(),
			"authoring session loads state through the injected persistence port",
		)
		_check(session.save_draft()["ok"], "authoring session saves through its port")
		_check(session.publish()["ok"], "authoring session publishes through its port")
		_check(
			persistence.draft_count == 1
			and persistence.publish_count == 1
			and persistence.last_artifact == artifact
			and persistence.last_revision == session.terrain_revision(),
			"persistence adapter receives the current artifact and revision",
		)
	terrain.queue_free()
	await Engine.get_main_loop().process_frame

func _test_regional_clamp_and_publish(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var space := TerrainSpaceTransform.new(artifact)
	var first := Vector2i(10, 10)
	var second := Vector2i(20, 10)
	surface.terrain().data.set_height(
		space.raster_pixel_to_terrain_local(first),
		artifact.maximum_at(first) + 50.0,
	)
	surface.terrain().data.set_height(
		space.raster_pixel_to_terrain_local(second),
		artifact.maximum_at(second) + 50.0,
	)
	var revision_before_edit := surface.terrain_revision
	surface.terrain().data.maps_edited.emit(AABB(
		space.raster_pixel_to_terrain_local(first),
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

func _test_incremental_overlay_refresh(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var reference := surface.get_node("ReferenceTexture") as MeshInstance3D
	var grid := surface.get_node("HexGrid") as MeshInstance3D
	var minimum := surface.get_node("MinimumHeightDebug") as MeshInstance3D
	var maximum := surface.get_node("MaximumHeightDebug") as MeshInstance3D
	var marker := surface.get_node("CityCoreMarker") as MeshInstance3D
	var reference_mesh := reference.mesh
	var grid_mesh := grid.mesh
	var minimum_mesh := minimum.mesh
	var maximum_mesh := maximum.mesh
	var marker_mesh := marker.mesh
	var pixel := Vector2i(5, 5)
	var next_height := artifact.clamp_height(pixel, surface.height_at(pixel) + 0.5)
	var started_at := Time.get_ticks_usec()
	surface.set_height(pixel, next_height)
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	var elapsed_micros := Time.get_ticks_usec() - started_at
	_check(
		reference.mesh == reference_mesh and grid.mesh == grid_mesh,
		"terrain edits reuse reference and grid mesh topology",
	)
	_check(
		minimum.mesh == minimum_mesh and maximum.mesh == maximum_mesh,
		"terrain edits do not rebuild static constraint overlays",
	)
	_check(marker.mesh == marker_mesh, "distant terrain edits do not rebuild the city marker")
	var space := TerrainSpaceTransform.new(artifact)
	var marker_pixel := space.terrain_local_to_raster_pixel(marker.position)
	marker_mesh = marker.mesh
	surface.set_height(
		marker_pixel,
		artifact.clamp_height(marker_pixel, surface.height_at(marker_pixel) + 0.25),
	)
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	_check(marker.mesh != marker_mesh, "a terrain edit below the city marker refreshes it")
	_check(
		elapsed_micros < 250_000,
		"one incremental Terrain3D stroke stays within the headless smoke budget",
	)

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
		and int(manifest["rasterWidth"]) == surface.artifact().width
		and int(manifest["rasterHeight"]) == surface.artifact().height
		and is_equal_approx(
			float(manifest["sampleSpacingMeters"]),
			surface.artifact().sample_spacing_meters,
		)
		and int(manifest["terrainRevision"]) == surface.terrain_revision,
		"published terrain records all required identities and terrainRevision",
	)
	_check(
		str(manifest["terrainDataDirectory"]).contains("/published/"),
		"published pointer targets a dedicated immutable snapshot",
	)

func _test_artifact_identity(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var store := AuthoringStore.new(surface.authoring_root)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "generatedBaseHash", "0".repeat(64)),
		"requiresConstraintRefresh",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "authoringProfileHash", "1".repeat(64)),
		"requiresConstraintRefresh",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "generatorVersion", "future-generator/1"),
		"unsupportedGenerator",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "rasterWidth", artifact.width + 1),
		"requiresMigration",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "mapContentHash", "f".repeat(64)),
		"belongsToDifferentMap",
	)
	var legacy_root := _test_root.path_join("legacy_terrain_authoring")
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(legacy_root.path_join("final"))
	)
	_assert_compatibility(
		AuthoringStore.new(legacy_root),
		artifact.identity(),
		"requiresMigration",
	)

func _assert_compatibility(
	store: AonwTerrainAuthoringStore,
	identity: AonwTerrainArtifactIdentity,
	expected: String,
) -> void:
	var result := store.load_revision(identity)
	_check(
		not result["ok"] and result.get("compatibility") == expected,
		"saved terrain reports explicit compatibility outcome: %s" % expected,
	)

func _with_identity(
	identity: AonwTerrainArtifactIdentity,
	field: String,
	value: Variant,
) -> AonwTerrainArtifactIdentity:
	var changed := identity.to_dictionary()
	changed[field] = value
	return AonwTerrainArtifactIdentity.new(changed)

func _directory_hashes(path: String) -> Dictionary:
	var result := {}
	var directory := DirAccess.open(ProjectSettings.globalize_path(path))
	if directory == null:
		return result
	var file_names := directory.get_files()
	file_names.sort()
	for file_name in file_names:
		result[file_name] = FileAccess.get_sha256(path.path_join(file_name))
	return result

func _test_snapshot_integrity(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
	directory: String,
) -> void:
	var region_path := directory.path_join("terrain3d_00_00.res")
	var original := FileAccess.get_file_as_bytes(region_path)
	var file := FileAccess.open(region_path, FileAccess.WRITE)
	if file == null:
		_check(false, "terrain snapshot region can be opened for integrity test")
		return
	file.store_buffer(original)
	file.store_8(0)
	file = null
	var result := AuthoringStore.new(surface.authoring_root).load_revision(artifact.identity())
	_check(not result["ok"], "snapshot hash validation rejects a modified Terrain3D region")
	file = FileAccess.open(region_path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(original)
	file = null

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
	var open_result: Dictionary = await _composition.open_surface(surface)
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

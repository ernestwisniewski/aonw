@tool
class_name AonwTerrainAuthoringSurface
extends Node3D

signal session_opened(result: Dictionary)

const ArtifactRepository := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const AuthoringStore := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_store.gd"
)
const AuthoringSession := preload(
	"res://editor/map_authoring/application/terrain_authoring_session.gd"
)
const OverlayBuilder := preload(
	"res://editor/map_authoring/presentation/terrain_overlay_mesh_builder.gd"
)

@export var source_map_id := ""
@export_dir var compiled_artifact_directory := ""
@export_dir var authoring_root := ""
@export var map_content_hash := ""
@export var authoring_profile_hash := ""
@export var generated_base_hash := ""
@export var generator_version := ""
@export var terrain_revision := 0
@export var reference_visible := true
@export_range(0.0, 1.0, 0.01) var reference_opacity := 0.65
@export var grid_visible := true
@export_range(0.0, 1.0, 0.01) var grid_opacity := 0.72
@export_range(0.01, 1.0, 0.01) var grid_width := 0.12
@export var constraints_visible := false
@export var city_marker_visible := true
@export var city_marker_coordinate := Vector2i(-1, -1)
@export var terrain_material: Terrain3DMaterial
@export var terrain_assets: Terrain3DAssets

var _artifact_repository := ArtifactRepository.new()
var _overlay_builder := OverlayBuilder.new()
var _artifact: AonwTerrainCompiledArtifact
var _session: AonwTerrainAuthoringSession
var _terrain: Terrain3D
var _reference: MeshInstance3D
var _grid: MeshInstance3D
var _minimum_debug: MeshInstance3D
var _maximum_debug: MeshInstance3D
var _city_marker: MeshInstance3D
var _reference_texture: Texture2D
var _overlay_refresh_queued := false

func _ready() -> void:
	_ensure_nodes()
	_open_session.call_deferred()

func configure(
	map_id: String,
	artifact_directory: String,
	session_root: String,
) -> void:
	source_map_id = map_id
	compiled_artifact_directory = artifact_directory
	authoring_root = session_root
	_ensure_nodes()

func assign_generated_owners(scene_owner: Node) -> void:
	_ensure_nodes()
	for child in [_terrain, _reference, _grid, _minimum_debug, _maximum_debug, _city_marker]:
		child.owner = scene_owner

func terrain() -> Terrain3D:
	_ensure_nodes()
	return _terrain

func artifact() -> AonwTerrainCompiledArtifact:
	return _artifact

func is_session_open() -> bool:
	return _session != null

func set_reference_visible(value: bool) -> void:
	reference_visible = value
	_ensure_nodes()
	_reference.visible = value

func set_reference_opacity(value: float) -> void:
	reference_opacity = clampf(value, 0.0, 1.0)
	_update_opacity(_reference, reference_opacity)

func set_grid_visible(value: bool) -> void:
	grid_visible = value
	_ensure_nodes()
	_grid.visible = value

func set_grid_opacity(value: float) -> void:
	grid_opacity = clampf(value, 0.0, 1.0)
	_update_opacity(_grid, grid_opacity)

func set_constraints_visible(value: bool) -> void:
	constraints_visible = value
	_ensure_nodes()
	_minimum_debug.visible = value
	_maximum_debug.visible = value

func set_city_marker_visible(value: bool) -> void:
	city_marker_visible = value
	_ensure_nodes()
	_city_marker.visible = value

func set_city_marker_coordinate(value: Vector2i) -> void:
	city_marker_coordinate = value
	_refresh_city_marker()

func change_height(history: UndoRedo, pixel: Vector2i, requested_height: float) -> bool:
	if _session == null:
		return false
	return _session.change_height(history, pixel, requested_height)

func set_height(pixel: Vector2i, requested_height: float) -> float:
	assert(_session != null, "Terrain authoring session is not open")
	return _session.set_height(pixel, requested_height)

func height_at(pixel: Vector2i) -> float:
	assert(_session != null, "Terrain authoring session is not open")
	return _session.height_at(pixel)

func clamp_changed_region(changed_pixels: Rect2i) -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	return _session.clamp_changed_region(changed_pixels)

func validate_for_publish() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	return _session.validate_for_publish()

func save_draft() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var result := _session.save_draft()
	_sync_metadata()
	return result

func publish() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var result := _session.publish()
	_sync_metadata()
	return result

func refresh_generated_artifact() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var artifact_result := _artifact_repository.load_artifact(
		compiled_artifact_directory,
		source_map_id,
	)
	if not artifact_result["ok"]:
		return artifact_result
	var result := _session.refresh_generated_artifact(artifact_result["artifact"])
	if not result["ok"]:
		return result
	_artifact = artifact_result["artifact"]
	_sync_metadata()
	refresh_overlays()
	return result

func refresh_overlays() -> void:
	if _session == null or _artifact == null or _reference_texture == null:
		return
	_reference.mesh = _overlay_builder.reference_mesh(
		_artifact,
		_terrain.data,
		_reference_texture,
		reference_opacity,
	)
	_reference.transform = _artifact.reference_transform()
	_grid.mesh = _overlay_builder.grid_mesh(
		_artifact,
		_terrain.data,
		grid_width,
		grid_opacity,
	)
	_minimum_debug.mesh = _overlay_builder.constraint_mesh(
		_artifact,
		_artifact.minimum_image,
		Color(0.15, 0.45, 1.0, 0.22),
		-OverlayBuilder.CONSTRAINT_OFFSET,
	)
	_maximum_debug.mesh = _overlay_builder.constraint_mesh(
		_artifact,
		_artifact.maximum_image,
		Color(1.0, 0.2, 0.15, 0.22),
		OverlayBuilder.CONSTRAINT_OFFSET,
	)
	_refresh_city_marker()
	_apply_visibility()

func _open_session() -> void:
	if source_map_id.is_empty() or compiled_artifact_directory.is_empty() or authoring_root.is_empty():
		session_opened.emit(_failure("terrain authoring scene is not configured"))
		return
	_ensure_nodes()
	if _terrain.data == null:
		await get_tree().process_frame
	var artifact_result := _artifact_repository.load_artifact(
		compiled_artifact_directory,
		source_map_id,
	)
	if not artifact_result["ok"]:
		session_opened.emit(artifact_result)
		return
	_artifact = artifact_result["artifact"]
	_terrain.vertex_spacing = _artifact.sample_spacing_meters
	var store := AuthoringStore.new(authoring_root)
	_reference_texture = ResourceLoader.load(
		store.reference_texture_path(),
		"Texture2D",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as Texture2D
	if _reference_texture == null:
		session_opened.emit(_failure("terrain reference texture is missing"))
		return
	_session = AuthoringSession.new(_terrain.data, _artifact, store)
	var open_result := _session.open()
	if not open_result["ok"]:
		_session = null
		session_opened.emit(open_result)
		return
	if not _session.terrain_changed.is_connected(_on_terrain_changed):
		_session.terrain_changed.connect(_on_terrain_changed)
	if city_marker_coordinate.x < 0 or city_marker_coordinate.y < 0:
		city_marker_coordinate = Vector2i(_artifact.cols / 2, _artifact.rows / 2)
	_sync_metadata()
	refresh_overlays()
	session_opened.emit({"ok": true})

func _ensure_nodes() -> void:
	_terrain = get_node_or_null("Terrain3D") as Terrain3D
	if _terrain == null:
		_terrain = Terrain3D.new()
		_terrain.name = "Terrain3D"
		add_child(_terrain)
	_terrain.free_editor_textures = false
	if terrain_material == null:
		terrain_material = Terrain3DMaterial.new()
	if terrain_assets == null:
		terrain_assets = Terrain3DAssets.new()
	_terrain.material = terrain_material
	_terrain.assets = terrain_assets
	_reference = _mesh_node("ReferenceTexture")
	_grid = _mesh_node("HexGrid")
	_minimum_debug = _mesh_node("MinimumHeightDebug")
	_maximum_debug = _mesh_node("MaximumHeightDebug")
	_city_marker = _mesh_node("CityCoreMarker")
	_apply_visibility()

func _mesh_node(node_name: StringName) -> MeshInstance3D:
	var node := get_node_or_null(NodePath(node_name)) as MeshInstance3D
	if node == null:
		node = MeshInstance3D.new()
		node.name = node_name
		add_child(node)
	return node

func _refresh_city_marker() -> void:
	if _artifact == null or _terrain == null or _terrain.data == null:
		return
	if (
		city_marker_coordinate.x < 0
		or city_marker_coordinate.x >= _artifact.cols
		or city_marker_coordinate.y < 0
		or city_marker_coordinate.y >= _artifact.rows
	):
		_city_marker.mesh = null
		return
	var marker := _overlay_builder.city_marker(
		_artifact,
		_terrain.data,
		city_marker_coordinate,
	)
	_city_marker.mesh = marker["mesh"]
	_city_marker.position = marker["position"]
	_city_marker.visible = city_marker_visible

func _on_terrain_changed(_changed_pixels: Rect2i) -> void:
	_sync_metadata()
	if _overlay_refresh_queued:
		return
	_overlay_refresh_queued = true
	_refresh_overlays_deferred.call_deferred()

func _refresh_overlays_deferred() -> void:
	_overlay_refresh_queued = false
	refresh_overlays()

func _sync_metadata() -> void:
	if _artifact == null:
		return
	map_content_hash = _artifact.map_content_hash
	authoring_profile_hash = _artifact.authoring_profile_hash
	generated_base_hash = _artifact.generated_base_hash
	generator_version = _artifact.generator_version
	terrain_revision = _session.terrain_revision() if _session != null else terrain_revision

func _apply_visibility() -> void:
	if _reference != null:
		_reference.visible = reference_visible
	if _grid != null:
		_grid.visible = grid_visible
	if _minimum_debug != null:
		_minimum_debug.visible = constraints_visible
	if _maximum_debug != null:
		_maximum_debug.visible = constraints_visible
	if _city_marker != null:
		_city_marker.visible = city_marker_visible

func _update_opacity(layer: MeshInstance3D, value: float) -> void:
	if layer == null or layer.mesh == null or layer.mesh.get_surface_count() == 0:
		return
	var material := layer.mesh.surface_get_material(0) as StandardMaterial3D
	if material == null:
		return
	var color := material.albedo_color
	color.a = value
	material.albedo_color = color

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

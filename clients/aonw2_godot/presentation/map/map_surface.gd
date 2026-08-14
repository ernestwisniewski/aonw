@tool
class_name AonwMapSurface
extends Node3D

const MeshBuilder := preload("res://presentation/map/map_surface_mesh_builder.gd")
const RenderSettings := preload("res://presentation/map/map_render_settings.gd")
const Terrain3DRasterizer := preload(
	"res://presentation/map/terrain3d/terrain3d_map_rasterizer.gd"
)
const Terrain3DAdapter := preload(
	"res://presentation/map/terrain3d/terrain3d_runtime_adapter.gd"
)

signal map_presented(world_size: Vector2, maximum_height: float)

const GRID_SURFACE_OFFSET := 0.035

@export var source_map_id := ""
@export var source_map_path := ""
@export var source_visual_directory := ""
@export var render_settings: Resource = RenderSettings.new()
@export var terrain_mesh_resource: ArrayMesh
@export var reference_mesh_resource: ArrayMesh
@export var grid_mesh_resource: ArrayMesh
@export var terrain3d_data_directory := ""
@export var terrain3d_version := ""
@export var terrain3d_image_size := Vector2i.ZERO
@export var terrain3d_import_origin := Vector3.ZERO
@export var terrain3d_vertex_spacing := 0.0
@export var terrain3d_region_count := Vector2i.ZERO
@export var terrain3d_active_region_count := 0

var _builder := MeshBuilder.new()
var _terrain3d_rasterizer := Terrain3DRasterizer.new()
var _terrain3d_adapter := Terrain3DAdapter.new()
var _document: AonwMapDocument
var _terrain_texture: Texture2D
var _reference_texture: Texture2D
var _terrain: MeshInstance3D
var _reference: MeshInstance3D
var _grid: MeshInstance3D
var _terrain3d_ground: Node3D
var _terrain3d_error := ""
var _ignore_settings_changed := false
var _connected_settings: Resource

func _ready() -> void:
	_connect_settings()
	_ensure_layers()
	_validate_loaded_backend()
	_apply_visibility()
	_update_material_opacity(_reference, render_settings.reference_opacity)
	_update_material_opacity(_grid, render_settings.grid_opacity)

func present(
	document: AonwMapDocument,
	terrain_texture: Texture2D,
	reference_texture: Texture2D,
) -> void:
	_document = document
	_terrain_texture = terrain_texture
	_reference_texture = reference_texture
	_rebuild()

func configure_source(source: AonwMapSource) -> void:
	source_map_id = source.map_id
	source_map_path = source.map_path
	source_visual_directory = source.visual_directory

func apply_render_settings(value: Resource) -> void:
	_disconnect_settings()
	render_settings = value.snapshot() if value != null else RenderSettings.new()
	_connect_settings()
	_rebuild()
	_apply_visibility()

func set_reference_visible(value: bool) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.reference_visible = value)
	if render_settings.terrain_backend == RenderSettings.TerrainBackend.TERRAIN_3D:
		_rebuild()
	else:
		_reference.visible = render_settings.reference_visible

func set_reference_opacity(value: float) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.reference_opacity = value)
	if render_settings.terrain_backend == RenderSettings.TerrainBackend.TERRAIN_3D:
		_rebuild()
	else:
		_update_material_opacity(_reference, render_settings.reference_opacity)

func set_grid_visible(value: bool) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.grid_visible = value)
	_grid.visible = render_settings.grid_visible

func set_grid_opacity(value: float) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.grid_opacity = value)
	_update_material_opacity(_grid, render_settings.grid_opacity)

func set_grid_width(value: float) -> void:
	set_geometry(render_settings.height_step, value)

func set_height_step(value: float) -> void:
	set_geometry(value, render_settings.grid_width)

func set_geometry(value_height_step: float, value_grid_width: float) -> void:
	set_render_configuration(
		value_height_step,
		value_grid_width,
		render_settings.terrain_backend,
		render_settings.terrain_samples_per_radius,
		render_settings.terrain3d_region_size,
	)

func set_terrain_backend(value: int) -> void:
	set_render_configuration(
		render_settings.height_step,
		render_settings.grid_width,
		value,
		render_settings.terrain_samples_per_radius,
		render_settings.terrain3d_region_size,
	)

func set_terrain_resolution(samples_per_radius: int, region_size: int) -> void:
	set_render_configuration(
		render_settings.height_step,
		render_settings.grid_width,
		render_settings.terrain_backend,
		samples_per_radius,
		region_size,
	)

func set_render_configuration(
	value_height_step: float,
	value_grid_width: float,
	value_backend: int,
	value_samples_per_radius: int,
	value_region_size: int,
) -> void:
	_ignore_settings_changed = true
	render_settings.height_step = value_height_step
	render_settings.grid_width = value_grid_width
	render_settings.terrain_backend = value_backend
	render_settings.terrain_samples_per_radius = value_samples_per_radius
	render_settings.terrain3d_region_size = value_region_size
	_ignore_settings_changed = false
	_rebuild()

func has_editing_context() -> bool:
	return _document != null and _terrain_texture != null and _reference_texture != null

func terrain_mesh() -> ArrayMesh:
	_ensure_layers()
	return terrain_mesh_resource

func reference_mesh() -> ArrayMesh:
	_ensure_layers()
	return reference_mesh_resource

func grid_mesh() -> ArrayMesh:
	_ensure_layers()
	return grid_mesh_resource

func replace_persisted_resources(
	terrain: ArrayMesh,
	reference: ArrayMesh,
	grid: ArrayMesh,
	settings: Resource = null,
) -> void:
	_ensure_layers()
	_reference.material_override = null
	_grid.material_override = null
	_set_mesh_resources(terrain, reference, grid)
	if settings != null:
		_disconnect_settings()
		render_settings = settings
		_connect_settings()
	_apply_visibility()

func restore_editing_context(document: AonwMapDocument) -> bool:
	_ensure_layers()
	var terrain_texture := _mesh_texture(terrain_mesh_resource)
	var reference_texture := _mesh_texture(reference_mesh_resource)
	if terrain_texture == null or reference_texture == null:
		return false
	_document = document
	_terrain_texture = terrain_texture
	_reference_texture = reference_texture
	return true

func assign_layer_owners(scene_owner: Node) -> void:
	_ensure_layers()
	_terrain.owner = scene_owner
	_reference.owner = scene_owner
	_grid.owner = scene_owner
	_assign_terrain3d_owners(scene_owner)

func validate_backend() -> Dictionary:
	if render_settings.terrain_backend != RenderSettings.TerrainBackend.TERRAIN_3D:
		return {"ok": true}
	if not Terrain3DAdapter.is_available():
		return {"ok": false, "message": Terrain3DAdapter.availability_message()}
	if not _terrain3d_error.is_empty():
		return {"ok": false, "message": _terrain3d_error}
	if _terrain3d_ground == null:
		return {"ok": false, "message": "Terrain3D backend was not generated"}
	var live_region_count := _terrain3d_adapter.active_region_count(_terrain3d_ground)
	if live_region_count <= 0:
		return {"ok": false, "message": "Terrain3D backend has no active regions"}
	terrain3d_active_region_count = live_region_count
	return {"ok": true}

func backend_status() -> String:
	if render_settings.terrain_backend != RenderSettings.TerrainBackend.TERRAIN_3D:
		return "Legacy mesh backend"
	if not _terrain3d_error.is_empty():
		return _terrain3d_error
	return Terrain3DAdapter.availability_message()

func terrain_backend_name() -> String:
	return render_settings.terrain_backend_name()

func terrain3d_manifest() -> Dictionary:
	var enabled := render_settings.terrain_backend == RenderSettings.TerrainBackend.TERRAIN_3D
	return {
		"enabled": enabled,
		"available": Terrain3DAdapter.is_available(),
		"version": terrain3d_version,
		"dataDirectory": terrain3d_data_directory,
		"regionSize": render_settings.terrain3d_region_size,
		"samplesPerRadius": render_settings.terrain_samples_per_radius,
		"vertexSpacing": terrain3d_vertex_spacing,
		"imageSize": {
			"width": terrain3d_image_size.x,
			"height": terrain3d_image_size.y,
		},
		"regionGrid": {
			"columns": terrain3d_region_count.x,
			"rows": terrain3d_region_count.y,
		},
		"activeRegionCount": terrain3d_active_region_count,
		"importOrigin": {
			"x": terrain3d_import_origin.x,
			"y": terrain3d_import_origin.y,
			"z": terrain3d_import_origin.z,
		},
	}

func persist_backend_data(path: String) -> Dictionary:
	if render_settings.terrain_backend != RenderSettings.TerrainBackend.TERRAIN_3D:
		terrain3d_data_directory = ""
		return {"ok": true, "backend": terrain_backend_name()}
	var validation := validate_backend()
	if not validation["ok"]:
		return validation
	var result := _terrain3d_adapter.save_directory(_terrain3d_ground, path)
	if not result["ok"]:
		return result
	terrain3d_data_directory = path
	terrain3d_version = result["version"]
	terrain3d_active_region_count = int(result["region_count"])
	return result

func uses_terrain3d() -> bool:
	return (
		render_settings.terrain_backend == RenderSettings.TerrainBackend.TERRAIN_3D
		and _terrain3d_ground != null
		and _terrain3d_error.is_empty()
	)

func height_at_local_point(point: Vector3) -> float:
	if not uses_terrain3d():
		return point.y
	var global_probe := to_global(Vector3(point.x, 0.0, point.z))
	var global_height := _terrain3d_adapter.height_at(_terrain3d_ground, global_probe)
	if is_nan(global_height):
		return point.y
	return to_local(Vector3(global_probe.x, global_height, global_probe.z)).y

func intersect_global_ray(global_origin: Vector3, global_direction: Vector3) -> Dictionary:
	if not uses_terrain3d():
		return {"ok": false, "message": "Terrain3D backend is not active"}
	return _terrain3d_adapter.intersect(
		_terrain3d_ground,
		global_origin,
		global_direction,
	)

func _validate_loaded_backend() -> void:
	if render_settings.terrain_backend != RenderSettings.TerrainBackend.TERRAIN_3D:
		return
	if not Terrain3DAdapter.is_available():
		_terrain3d_error = Terrain3DAdapter.availability_message()
		return
	if _terrain3d_ground == null:
		_terrain3d_error = "Terrain3D scene does not contain persisted terrain data"
		return
	var region_count := _terrain3d_adapter.active_region_count(_terrain3d_ground)
	if region_count <= 0:
		_terrain3d_error = "Terrain3D could not load any persisted regions"
		return
	terrain3d_active_region_count = region_count
	terrain3d_version = _terrain3d_adapter.version(_terrain3d_ground)

func _rebuild() -> void:
	if _document == null or _terrain_texture == null or _reference_texture == null:
		return
	_ensure_layers()
	var result := _builder.build(
		_document,
		_terrain_texture,
		_reference_texture,
		render_settings,
	)
	_reference.material_override = null
	_grid.material_override = null
	_set_mesh_resources(
		result["terrain_mesh"],
		result["reference_mesh"],
		result["grid_mesh"],
	)
	_rebuild_terrain_backend()
	if uses_terrain3d():
		_project_grid_to_active_backend()
	_apply_visibility()
	map_presented.emit(result["world_size"], result["maximum_height"])

func _rebuild_terrain_backend() -> void:
	_clear_terrain3d_ground()
	_terrain3d_error = ""
	if render_settings.terrain_backend != RenderSettings.TerrainBackend.TERRAIN_3D:
		_clear_terrain3d_metadata()
		return
	var artifact := _terrain3d_rasterizer.build(
		_document,
		_reference_texture,
		render_settings,
	)
	if not artifact["ok"]:
		_terrain3d_error = artifact["message"]
		_clear_terrain3d_metadata()
		return
	var created := _terrain3d_adapter.create_ground(artifact, self)
	if not created["ok"]:
		_terrain3d_error = created["message"]
		_clear_terrain3d_metadata()
		return
	_terrain3d_ground = created["ground"]
	if _terrain3d_ground.get_parent() == null:
		add_child(_terrain3d_ground)
	var scene_owner := owner if owner != null else self
	_assign_terrain3d_owners(scene_owner)
	terrain3d_data_directory = ""
	terrain3d_version = created["version"]
	terrain3d_image_size = artifact["image_size"]
	terrain3d_import_origin = artifact["import_origin"]
	terrain3d_vertex_spacing = artifact["vertex_spacing"]
	terrain3d_region_count = artifact["region_count"]
	terrain3d_active_region_count = int(created["region_count"])

func _ensure_layers() -> void:
	if _terrain == null:
		_terrain = get_node_or_null("BaseTerrain") as MeshInstance3D
	if _terrain == null:
		_terrain = MeshInstance3D.new()
		_terrain.name = "BaseTerrain"
		add_child(_terrain)
	if _reference == null:
		_reference = get_node_or_null("ReferenceTexture") as MeshInstance3D
	if _reference == null:
		_reference = MeshInstance3D.new()
		_reference.name = "ReferenceTexture"
		add_child(_reference)
	if _grid == null:
		_grid = get_node_or_null("HexGrid") as MeshInstance3D
	if _grid == null:
		_grid = MeshInstance3D.new()
		_grid.name = "HexGrid"
		add_child(_grid)
	if _terrain3d_ground == null:
		_terrain3d_ground = get_node_or_null("Terrain3DGround") as Node3D
	if terrain_mesh_resource == null:
		terrain_mesh_resource = _terrain.mesh
	if reference_mesh_resource == null:
		reference_mesh_resource = _reference.mesh
	if grid_mesh_resource == null:
		grid_mesh_resource = _grid.mesh
	_terrain.mesh = terrain_mesh_resource
	_reference.mesh = reference_mesh_resource
	_grid.mesh = grid_mesh_resource

func _set_mesh_resources(terrain: ArrayMesh, reference: ArrayMesh, grid: ArrayMesh) -> void:
	terrain_mesh_resource = terrain
	reference_mesh_resource = reference
	grid_mesh_resource = grid
	_terrain.mesh = terrain_mesh_resource
	_reference.mesh = reference_mesh_resource
	_grid.mesh = grid_mesh_resource

func _apply_visibility() -> void:
	var terrain3d_active := uses_terrain3d()
	if _terrain != null:
		_terrain.visible = not terrain3d_active
	if _reference != null:
		_reference.visible = render_settings.reference_visible and not terrain3d_active
	if _terrain3d_ground != null:
		_terrain3d_ground.visible = terrain3d_active
	if _grid != null:
		_grid.visible = render_settings.grid_visible

func _connect_settings() -> void:
	if render_settings == null:
		render_settings = RenderSettings.new()
	if _connected_settings == render_settings:
		return
	_disconnect_settings()
	_connected_settings = render_settings
	if not _connected_settings.changed.is_connected(_on_settings_changed):
		_connected_settings.changed.connect(_on_settings_changed)

func _disconnect_settings() -> void:
	if (
		_connected_settings != null
		and _connected_settings.changed.is_connected(_on_settings_changed)
	):
		_connected_settings.changed.disconnect(_on_settings_changed)
	_connected_settings = null

func _update_setting(change: Callable) -> void:
	_ignore_settings_changed = true
	change.call()
	_ignore_settings_changed = false

func _on_settings_changed() -> void:
	if _ignore_settings_changed:
		return
	_rebuild()
	_apply_visibility()

func _mesh_texture(mesh: Mesh) -> Texture2D:
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	var material := mesh.surface_get_material(0) as StandardMaterial3D
	return material.albedo_texture if material != null else null

func _update_material_opacity(layer: MeshInstance3D, value: float) -> void:
	if layer == null or layer.mesh == null or layer.mesh.get_surface_count() == 0:
		return
	var material := layer.material_override as StandardMaterial3D
	if material == null:
		var mesh_material := layer.mesh.surface_get_material(0) as StandardMaterial3D
		if mesh_material != null:
			material = mesh_material.duplicate() as StandardMaterial3D
			material.resource_local_to_scene = true
			layer.material_override = material
	if material == null:
		return
	var color := material.albedo_color
	color.a = value
	material.albedo_color = color

func _clear_terrain3d_ground() -> void:
	if _terrain3d_ground == null:
		return
	if _terrain3d_ground.get_parent() == self:
		remove_child(_terrain3d_ground)
	_terrain3d_ground.free()
	_terrain3d_ground = null

func _clear_terrain3d_metadata() -> void:
	terrain3d_data_directory = ""
	terrain3d_version = ""
	terrain3d_image_size = Vector2i.ZERO
	terrain3d_import_origin = Vector3.ZERO
	terrain3d_vertex_spacing = 0.0
	terrain3d_region_count = Vector2i.ZERO
	terrain3d_active_region_count = 0

func _project_grid_to_active_backend() -> void:
	if not uses_terrain3d() or grid_mesh_resource == null:
		return
	if grid_mesh_resource.get_surface_count() == 0:
		return
	var arrays := grid_mesh_resource.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for index in range(vertices.size()):
		var vertex := vertices[index]
		vertex.y = height_at_local_point(vertex) + GRID_SURFACE_OFFSET
		vertices[index] = vertex
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var projected := ArrayMesh.new()
	projected.add_surface_from_arrays(
		grid_mesh_resource.surface_get_primitive_type(0),
		arrays,
	)
	var material := grid_mesh_resource.surface_get_material(0)
	if material != null:
		projected.surface_set_material(0, material)
	grid_mesh_resource = projected
	_grid.mesh = projected

func _assign_terrain3d_owners(scene_owner: Node) -> void:
	if _terrain3d_ground == null:
		return
	_terrain3d_ground.owner = scene_owner
	var terrain := _terrain3d_adapter.terrain_node(_terrain3d_ground)
	if terrain != null:
		terrain.owner = scene_owner

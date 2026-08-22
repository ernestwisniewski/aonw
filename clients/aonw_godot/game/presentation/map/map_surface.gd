@tool
class_name AonwMapSurface
extends Node3D

const MeshBuilder := preload("res://game/presentation/map/map_surface_mesh_builder.gd")
const RenderSettings := preload("res://game/presentation/map/map_render_settings.gd")

signal map_presented(world_size: Vector2, maximum_height: float)

@export var source_map_id := ""
@export var source_map_path := ""
@export var source_visual_directory := ""
@export var render_settings: Resource = RenderSettings.new()
@export var terrain_mesh_resource: ArrayMesh
@export var reference_mesh_resource: ArrayMesh
@export var grid_mesh_resource: ArrayMesh

var _builder := MeshBuilder.new()
var _document: AonwMapDocument
var _terrain_texture: Texture2D
var _reference_texture: Texture2D
var _terrain: MeshInstance3D
var _reference: MeshInstance3D
var _grid: MeshInstance3D
var _ignore_settings_changed := false
var _connected_settings: Resource

func _ready() -> void:
	_connect_settings()
	_ensure_layers()
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
	_reference.visible = render_settings.reference_visible

func set_reference_opacity(value: float) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.reference_opacity = value)
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
	_ignore_settings_changed = true
	render_settings.height_step = value_height_step
	render_settings.grid_width = value_grid_width
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
	_apply_visibility()
	map_presented.emit(result["world_size"], result["maximum_height"])

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

func assign_layer_owners(scene_owner: Node) -> void:
	_ensure_layers()
	_terrain.owner = scene_owner
	_reference.owner = scene_owner
	_grid.owner = scene_owner

func _apply_visibility() -> void:
	if _reference != null:
		_reference.visible = render_settings.reference_visible
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

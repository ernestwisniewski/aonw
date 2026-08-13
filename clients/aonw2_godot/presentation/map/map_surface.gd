@tool
class_name AonwMapSurface
extends Node3D

const MeshBuilder := preload("res://presentation/map/map_surface_mesh_builder.gd")

signal map_presented(world_size: Vector2, maximum_height: float)

@export var source_map_id := ""
@export var source_map_path := ""
@export var source_visual_directory := ""
@export var source_is_legacy := false
@export_range(0.25, 4.0, 0.05) var hex_radius := 1.0
@export_range(0.0, 1.0, 0.01) var height_step := 0.16:
	set(value):
		height_step = value
		_rebuild()
@export var reference_visible := true:
	set(value):
		reference_visible = value
		if _reference != null:
			_reference.visible = value
@export_range(0.0, 1.0, 0.01) var reference_opacity := 1.0:
	set(value):
		reference_opacity = value
		_update_material_opacity(_reference, value)
@export var grid_visible := true:
	set(value):
		grid_visible = value
		if _grid != null:
			_grid.visible = value
@export_range(0.0, 1.0, 0.01) var grid_opacity := 0.72:
	set(value):
		grid_opacity = value
		_update_material_opacity(_grid, value)

var _builder := MeshBuilder.new()
var _document: AonwMapDocument
var _terrain_texture: Texture2D
var _reference_texture: Texture2D
var _terrain: MeshInstance3D
var _reference: MeshInstance3D
var _grid: MeshInstance3D

func _ready() -> void:
	_ensure_layers()
	_apply_visibility()
	_update_material_opacity(_reference, reference_opacity)
	_update_material_opacity(_grid, grid_opacity)

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
	source_is_legacy = source.is_legacy()

func set_reference_visible(value: bool) -> void:
	reference_visible = value

func set_reference_opacity(value: float) -> void:
	reference_opacity = clampf(value, 0.0, 1.0)

func set_grid_visible(value: bool) -> void:
	grid_visible = value

func set_grid_opacity(value: float) -> void:
	grid_opacity = clampf(value, 0.0, 1.0)

func set_height_step(value: float) -> void:
	height_step = clampf(value, 0.0, 1.0)

func terrain_mesh() -> ArrayMesh:
	_ensure_layers()
	return _terrain.mesh

func reference_mesh() -> ArrayMesh:
	_ensure_layers()
	return _reference.mesh

func grid_mesh() -> ArrayMesh:
	_ensure_layers()
	return _grid.mesh

func replace_persisted_resources(
	terrain: ArrayMesh,
	reference: ArrayMesh,
	grid: ArrayMesh,
) -> void:
	_ensure_layers()
	_terrain.mesh = terrain
	_reference.mesh = reference
	_grid.mesh = grid
	_apply_visibility()

func _rebuild() -> void:
	if _document == null or _terrain_texture == null or _reference_texture == null:
		return
	_ensure_layers()
	var result := _builder.build(
		_document,
		_terrain_texture,
		_reference_texture,
		hex_radius,
		height_step,
		reference_opacity,
		grid_opacity,
	)
	_terrain.mesh = result["terrain_mesh"]
	_reference.mesh = result["reference_mesh"]
	_grid.mesh = result["grid_mesh"]
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

func assign_layer_owners(scene_owner: Node) -> void:
	_ensure_layers()
	_terrain.owner = scene_owner
	_reference.owner = scene_owner
	_grid.owner = scene_owner

func _apply_visibility() -> void:
	if _reference != null:
		_reference.visible = reference_visible
	if _grid != null:
		_grid.visible = grid_visible

func _update_material_opacity(layer: MeshInstance3D, value: float) -> void:
	if layer == null or layer.mesh == null or layer.mesh.get_surface_count() == 0:
		return
	var material := layer.mesh.surface_get_material(0) as StandardMaterial3D
	if material == null:
		return
	var color := material.albedo_color
	color.a = value
	material.albedo_color = color

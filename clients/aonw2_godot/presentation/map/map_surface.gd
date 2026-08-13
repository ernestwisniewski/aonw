class_name AonwMapSurface
extends Node3D

const MeshBuilder := preload("res://presentation/map/map_surface_mesh_builder.gd")

signal map_presented(world_size: Vector2)

@export_range(0.25, 4.0, 0.05) var hex_radius := 1.0
@export_range(0.0, 1.0, 0.01) var height_step := 0.16
@export var grid_visible := true:
	set(value):
		grid_visible = value
		if is_node_ready():
			_grid.visible = value

@onready var _terrain: MeshInstance3D = %Terrain
@onready var _grid: MeshInstance3D = %Grid

var _builder := MeshBuilder.new()
var _map_texture: Texture2D

func present(document: AonwMapDocument, map_texture: Texture2D) -> void:
	_map_texture = map_texture
	var result := _builder.build(document, map_texture, hex_radius, height_step)
	_terrain.mesh = result["terrain_mesh"]
	_grid.mesh = result["grid_mesh"]
	_grid.visible = grid_visible
	map_presented.emit(result["world_size"])

func set_grid_visible(value: bool) -> void:
	grid_visible = value

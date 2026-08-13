@tool
class_name AonwGenerateGodotMap
extends RefCounted

const MapSurface := preload("res://presentation/map/map_surface.gd")

var _open_map: AonwOpenMap
var _scene_repository: AonwGodotMapSceneRepository

func _init(
	open_map: AonwOpenMap,
	scene_repository: AonwGodotMapSceneRepository,
) -> void:
	_open_map = open_map
	_scene_repository = scene_repository

func execute(source: AonwMapSource, settings: Dictionary) -> Dictionary:
	var opened := _open_map.execute(source)
	if not opened["ok"]:
		return opened

	var surface := MapSurface.new()
	surface.name = "AonwMap3D"
	surface.hex_radius = float(settings.get("hex_radius", 1.0))
	surface.height_step = float(settings.get("height_step", 0.16))
	surface.reference_visible = bool(settings.get("reference_visible", true))
	surface.reference_opacity = float(settings.get("reference_opacity", 1.0))
	surface.grid_visible = bool(settings.get("grid_visible", true))
	surface.grid_opacity = float(settings.get("grid_opacity", 0.72))
	surface.grid_width = float(settings.get("grid_width", 0.04))
	surface.configure_source(source)
	surface.present(
		opened["document"],
		opened["terrain_texture"],
		opened["reference_texture"],
	)
	var result := _scene_repository.save(
		source,
		opened["document"],
		surface,
		opened["terrain_texture"],
		opened["reference_texture"],
		opened["content_hash"],
		opened["source_tile_size"],
		opened["missing_tiles"],
		opened["invalid_tiles"],
		opened["resized_tiles"],
	)
	surface.free()
	return result

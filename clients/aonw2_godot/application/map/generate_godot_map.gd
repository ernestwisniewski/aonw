@tool
class_name AonwGenerateGodotMap
extends RefCounted

const MapSurface := preload("res://presentation/map/map_surface.gd")
const RenderSettings := preload("res://presentation/map/map_render_settings.gd")

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
	surface.apply_render_settings(RenderSettings.from_dictionary(settings))
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

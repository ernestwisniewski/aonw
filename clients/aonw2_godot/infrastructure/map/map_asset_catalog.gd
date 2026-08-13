class_name AonwMapAssetCatalog
extends RefCounted

const MapSource := preload("res://application/map/map_source.gd")
const DEFAULT_CONTENT_ROOT := "res://../../content/maps"
const BUNDLED_ROOT := "res://assets/maps"
const REFERENCE_ART_ROOT := "res://../../assets/maps"

var _content_root: String
var _bundled_root: String
var _reference_art_root: String

func _init(
	content_root: String = DEFAULT_CONTENT_ROOT,
	bundled_root: String = BUNDLED_ROOT,
	reference_art_root: String = REFERENCE_ART_ROOT,
) -> void:
	_content_root = content_root
	_bundled_root = bundled_root
	_reference_art_root = reference_art_root

func discover() -> Array[AonwMapSource]:
	var sources: Array[AonwMapSource] = []
	_append_sources(sources, _content_root, _reference_art_root, "content")
	_append_sources(sources, _bundled_root, _bundled_root, "Godot")
	sources = _deduplicate(sources)
	sources.sort_custom(func(left: AonwMapSource, right: AonwMapSource) -> bool:
		if left.map_id == right.map_id:
			return left.origin < right.origin
		return left.map_id < right.map_id
	)
	return sources

func _append_sources(
	target: Array[AonwMapSource],
	root_path: String,
	visual_root: String,
	origin: String,
) -> void:
	var absolute_root := _resolve_path(root_path)
	var directory := DirAccess.open(absolute_root)
	if directory == null:
		return
	for directory_name in directory.get_directories():
		var source_directory := root_path.path_join(directory_name)
		var absolute_source_directory := absolute_root.path_join(directory_name)
		var map_path := source_directory.path_join("map.json")
		if not FileAccess.file_exists(absolute_source_directory.path_join("map.json")):
			continue
		target.append(AonwMapSource.new(
			directory_name,
			map_path,
			visual_root.path_join(directory_name),
			origin,
		))

func _deduplicate(sources: Array[AonwMapSource]) -> Array[AonwMapSource]:
	var result: Array[AonwMapSource] = []
	var selected := {}
	for source in sources:
		var key := source.map_id
		if selected.has(key):
			continue
		selected[key] = true
		result.append(source)
	return result

static func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path

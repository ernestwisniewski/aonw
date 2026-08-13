class_name AonwMapAssetCatalog
extends RefCounted

const MapSource := preload("res://application/map/map_source.gd")
const DEFAULT_LEGACY_ROOT := "res://../../assets/maps"
const DEFAULT_CONTENT_ROOT := "res://../../content/maps"
const BUNDLED_ROOT := "res://assets/maps"

var _legacy_root: String
var _content_root: String
var _bundled_root: String

func _init(
	legacy_root: String = DEFAULT_LEGACY_ROOT,
	content_root: String = DEFAULT_CONTENT_ROOT,
	bundled_root: String = BUNDLED_ROOT,
) -> void:
	_legacy_root = legacy_root
	_content_root = content_root
	_bundled_root = bundled_root

func discover() -> Array[AonwMapSource]:
	var sources: Array[AonwMapSource] = []
	_append_sources(sources, _legacy_root, AonwMapSource.Format.LEGACY, "assets")
	_append_sources(sources, _content_root, AonwMapSource.Format.VERSIONED, "content")
	_append_sources(sources, _bundled_root, AonwMapSource.Format.VERSIONED, "Godot")
	sources.sort_custom(func(left: AonwMapSource, right: AonwMapSource) -> bool:
		if left.map_id == right.map_id:
			return left.origin < right.origin
		return left.map_id < right.map_id
	)
	return _deduplicate(sources)

func _append_sources(
	target: Array[AonwMapSource],
	root_path: String,
	format: AonwMapSource.Format,
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
			source_directory,
			format,
			origin,
		))

func _deduplicate(sources: Array[AonwMapSource]) -> Array[AonwMapSource]:
	var result: Array[AonwMapSource] = []
	var selected := {}
	for source in sources:
		var key := "%s:%d" % [source.map_id, source.format]
		if selected.has(key):
			continue
		selected[key] = true
		result.append(source)
	return result

static func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path

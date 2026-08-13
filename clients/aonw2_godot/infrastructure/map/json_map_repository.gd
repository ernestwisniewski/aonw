class_name AonwJsonMapRepository
extends AonwMapDocumentReader

const MapDocument := preload("res://domain/map/map_document.gd")
const MapSource := preload("res://application/map/map_source.gd")

func load_map(source: AonwMapSource) -> Dictionary:
	var absolute_path := resolve_path(source.map_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return _failure("cannot open %s" % absolute_path)

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		return _failure(
			"invalid JSON at line %d: %s" % [
				parser.get_error_line(),
				parser.get_error_message(),
			]
		)
	if not parser.data is Dictionary:
		return _failure("map root must be an object")

	var result := (
		MapDocument.create_legacy(parser.data)
		if source.is_legacy()
		else MapDocument.create_versioned(parser.data)
	)
	if not result["ok"]:
		return result
	return {
		"ok": true,
		"document": result["value"],
		"source_path": absolute_path,
		"visual_directory": source.visual_directory,
		"source": source,
	}

static func resolve_path(source_path: String) -> String:
	if source_path.begins_with("res://") or source_path.begins_with("user://"):
		return ProjectSettings.globalize_path(source_path)
	return source_path

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

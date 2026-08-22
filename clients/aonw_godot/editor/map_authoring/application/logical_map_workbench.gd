class_name AonwLogicalMapWorkbench
extends RefCounted

func generate_map(_spec_document: String) -> Dictionary:
	return {
		"ok": false,
		"code": "logical_map_workbench_not_configured",
		"message": "logical map workbench is not configured",
	}

func reconfigure_terrain_height(
	_map_document: String,
	_terrain_authoring_document: String,
	_max_terrain_height_meters: float,
) -> Dictionary:
	return {
		"ok": false,
		"code": "logical_map_workbench_not_configured",
		"message": "logical map workbench is not configured",
	}

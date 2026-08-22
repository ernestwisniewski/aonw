class_name AonwLogicalMapWorkbench
extends RefCounted

func generate_map(_spec_document: String) -> Dictionary:
	return {
		"ok": false,
		"code": "logical_map_workbench_not_configured",
		"message": "logical map workbench is not configured",
	}

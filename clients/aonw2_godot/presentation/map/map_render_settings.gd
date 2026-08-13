@tool
class_name AonwMapRenderSettings
extends Resource

const FORMAT_VERSION := 1

@export_range(0.25, 4.0, 0.05) var hex_radius := 1.0:
	set(value):
		hex_radius = clampf(value, 0.25, 4.0)
		emit_changed()
@export_range(0.0, 1.0, 0.01) var height_step := 0.16:
	set(value):
		height_step = clampf(value, 0.0, 1.0)
		emit_changed()
@export var reference_visible := true:
	set(value):
		reference_visible = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var reference_opacity := 1.0:
	set(value):
		reference_opacity = clampf(value, 0.0, 1.0)
		emit_changed()
@export var grid_visible := true:
	set(value):
		grid_visible = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var grid_opacity := 0.72:
	set(value):
		grid_opacity = clampf(value, 0.0, 1.0)
		emit_changed()
@export_range(0.01, 0.12, 0.005) var grid_width := 0.04:
	set(value):
		grid_width = clampf(value, 0.01, 0.12)
		emit_changed()

static func from_dictionary(value: Dictionary) -> AonwMapRenderSettings:
	var settings := AonwMapRenderSettings.new()
	settings.hex_radius = float(value.get("hex_radius", 1.0))
	settings.height_step = float(value.get("height_step", 0.16))
	settings.reference_visible = bool(value.get("reference_visible", true))
	settings.reference_opacity = float(value.get("reference_opacity", 1.0))
	settings.grid_visible = bool(value.get("grid_visible", true))
	settings.grid_opacity = float(value.get("grid_opacity", 0.72))
	settings.grid_width = float(value.get("grid_width", 0.04))
	return settings

func snapshot() -> AonwMapRenderSettings:
	return duplicate(true) as AonwMapRenderSettings

func to_dictionary() -> Dictionary:
	return {
		"formatVersion": FORMAT_VERSION,
		"hexRadius": hex_radius,
		"heightStep": height_step,
		"referenceVisible": reference_visible,
		"referenceOpacity": reference_opacity,
		"gridVisible": grid_visible,
		"gridOpacity": grid_opacity,
		"gridWidth": grid_width,
	}

func equals(other: AonwMapRenderSettings) -> bool:
	return (
		other != null
		and is_equal_approx(hex_radius, other.hex_radius)
		and is_equal_approx(height_step, other.height_step)
		and reference_visible == other.reference_visible
		and is_equal_approx(reference_opacity, other.reference_opacity)
		and grid_visible == other.grid_visible
		and is_equal_approx(grid_opacity, other.grid_opacity)
		and is_equal_approx(grid_width, other.grid_width)
	)

@tool
class_name AonwMapWorkbenchView
extends VBoxContainer

const RenderSettings := preload("res://presentation/map/map_render_settings.gd")

var _map_picker := OptionButton.new()
var _generate_button := Button.new()
var _open_button := Button.new()
var _refresh_button := Button.new()
var _save_button := Button.new()
var _status := Label.new()
var _terrain_backend := OptionButton.new()
var _terrain_backend_status := Label.new()
var _terrain_samples := SpinBox.new()
var _terrain_region_size := OptionButton.new()
var _reference_toggle := CheckButton.new()
var _reference_opacity := HSlider.new()
var _reference_opacity_value := Label.new()
var _height_step := HSlider.new()
var _grid_toggle := CheckButton.new()
var _grid_opacity := HSlider.new()
var _grid_opacity_value := Label.new()
var _grid_width := HSlider.new()
var _geometry_update_timer := Timer.new()

func _build_interface() -> void:
	name = "AoNW Map"
	custom_minimum_size = Vector2(280.0, 0.0)

	var title := Label.new()
	title.text = "AoNW Map Workbench"
	title.add_theme_font_size_override("font_size", 17)
	add_child(title)

	var description := Label.new()
	description.text = "AoNW map → standalone Godot 3D scene"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	add_child(HSeparator.new())

	add_child(_section_label("Source map"))
	add_child(_map_picker)
	var source_actions := HBoxContainer.new()
	_refresh_button.text = "Refresh"
	_generate_button.text = "Generate / update 3D"
	_generate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_actions.add_child(_refresh_button)
	source_actions.add_child(_generate_button)
	add_child(source_actions)

	_open_button.text = "Open saved scene"
	add_child(_open_button)
	add_child(HSeparator.new())

	add_child(_section_label("Terrain"))
	_terrain_backend.add_item("Legacy mesh", RenderSettings.TerrainBackend.LEGACY_MESH)
	_terrain_backend.add_item("Terrain3D", RenderSettings.TerrainBackend.TERRAIN_3D)
	add_child(_control_with_label("Rendering backend", _terrain_backend))
	_terrain_backend_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_terrain_backend_status)

	_terrain_samples.min_value = 2.0
	_terrain_samples.max_value = 16.0
	_terrain_samples.step = 1.0
	_terrain_samples.value = 8.0
	_terrain_samples.tooltip_text = "Terrain3D height samples per logical hex radius"
	add_child(_control_with_label("Samples per hex radius", _terrain_samples))

	for size in RenderSettings.VALID_REGION_SIZES:
		_terrain_region_size.add_item(str(size), size)
	_select_option_by_id(_terrain_region_size, 256)
	_terrain_region_size.tooltip_text = "Terrain3D region width in vertices"
	add_child(_control_with_label("Terrain3D region size", _terrain_region_size))

	_height_step.min_value = 0.0
	_height_step.max_value = 1.0
	_height_step.step = 0.01
	_height_step.value = 0.16
	add_child(_control_with_label("Hex height", _height_step))

	add_child(_section_label("Original texture"))
	_reference_toggle.text = "Show reference texture"
	_reference_toggle.button_pressed = true
	add_child(_reference_toggle)
	_reference_opacity.min_value = 0.0
	_reference_opacity.max_value = 1.0
	_reference_opacity.step = 0.01
	_reference_opacity.value = 1.0
	_reference_opacity.tooltip_text = "0%: hidden, 100%: fully opaque"
	add_child(_opacity_control("Texture opacity", _reference_opacity, _reference_opacity_value))

	add_child(_section_label("Hex grid"))
	_grid_toggle.text = "Show hex outlines"
	_grid_toggle.button_pressed = true
	add_child(_grid_toggle)
	_grid_opacity.min_value = 0.0
	_grid_opacity.max_value = 1.0
	_grid_opacity.step = 0.01
	_grid_opacity.value = 0.72
	_grid_opacity.tooltip_text = "0%: hidden, 100%: fully opaque"
	add_child(_opacity_control("Outline opacity", _grid_opacity, _grid_opacity_value))
	_grid_width.min_value = 0.01
	_grid_width.max_value = 0.12
	_grid_width.step = 0.005
	_grid_width.value = 0.04
	_grid_width.tooltip_text = "Width of the geometric hex outlines"
	add_child(_control_with_label("Outline width", _grid_width))
	_geometry_update_timer.one_shot = true
	_geometry_update_timer.wait_time = 0.15
	add_child(_geometry_update_timer)
	_update_opacity_labels()
	_update_terrain_control_state()

	_save_button.text = "Save current scene"
	add_child(_save_button)
	add_child(HSeparator.new())
	_status.text = "Select a map from assets."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)

func selected_terrain_backend() -> int:
	return _terrain_backend.get_selected_id()

func selected_terrain_region_size() -> int:
	return _terrain_region_size.get_selected_id()

func set_terrain_backend_status(text: String) -> void:
	_terrain_backend_status.text = text

func _update_terrain_control_state() -> void:
	var terrain3d_selected := (
		selected_terrain_backend() == RenderSettings.TerrainBackend.TERRAIN_3D
	)
	_terrain_samples.editable = terrain3d_selected
	_terrain_region_size.disabled = not terrain3d_selected

func _select_option_by_id(option: OptionButton, id: int) -> void:
	for index in range(option.item_count):
		if option.get_item_id(index) == id:
			option.select(index)
			return

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label

func _control_with_label(text: String, control: Control) -> VBoxContainer:
	var container := VBoxContainer.new()
	var label := Label.new()
	label.text = text
	container.add_child(label)
	container.add_child(control)
	return container

func _opacity_control(text: String, slider: HSlider, value_label: Label) -> VBoxContainer:
	var container := VBoxContainer.new()
	var header := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 48.0
	header.add_child(label)
	header.add_child(value_label)
	container.add_child(header)
	container.add_child(slider)
	return container

func _update_opacity_labels() -> void:
	_reference_opacity_value.text = "%d%%" % roundi(_reference_opacity.value * 100.0)
	_grid_opacity_value.text = "%d%%" % roundi(_grid_opacity.value * 100.0)

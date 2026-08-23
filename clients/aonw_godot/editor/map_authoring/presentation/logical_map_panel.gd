@tool
class_name AonwLogicalMapPanel
extends VBoxContainer

signal edit_persisted(source: AonwMapSource, coordinate: Vector2i)
signal error_raised(message: String)
signal status_changed(message: String)

var _editor: AonwLogicalMapEditor
var _source: AonwMapSource
var _editable := false
var _busy := false
var _col := SpinBox.new()
var _row := SpinBox.new()
var _terrain := OptionButton.new()
var _resources := ItemList.new()
var _height := SpinBox.new()
var _reload := Button.new()
var _set_terrain := Button.new()
var _set_resources := Button.new()
var _set_height := Button.new()

func _ready() -> void:
	_build_interface()
	_reload.pressed.connect(refresh)
	_set_terrain.pressed.connect(_apply_terrain)
	_set_resources.pressed.connect(_apply_resources)
	_set_height.pressed.connect(_apply_height)
	_apply_enabled()

func configure(editor: AonwLogicalMapEditor) -> void:
	assert(editor != null, "Logical map editor is required")
	_editor = editor

func show_source(source: AonwMapSource, editable: bool) -> void:
	_source = source
	_editable = editable
	_apply_enabled()
	refresh()

func set_editable(value: bool) -> void:
	_editable = value
	_apply_enabled()

func refresh() -> void:
	if _editor == null or _source == null:
		return
	var result := _editor.inspect_tile(_source, _coordinate())
	if not result["ok"]:
		error_raised.emit(result["message"])
		return
	_apply_snapshot(result["snapshot"])

func _build_interface() -> void:
	if get_child_count() > 0:
		return
	var help := Label.new()
	help.text = "Rust edits canonical map.json. Open this map's Terrain3D scene before applying."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)
	var coordinates := HBoxContainer.new()
	_configure_coordinate(_col, "Logical tile column")
	_configure_coordinate(_row, "Logical tile row")
	coordinates.add_child(_labeled_control("Col", _col))
	coordinates.add_child(_labeled_control("Row", _row))
	add_child(coordinates)
	_reload.text = "Load logical tile"
	add_child(_reload)
	add_child(_labeled_control("Terrain", _terrain))
	_set_terrain.text = "Set tile terrain"
	add_child(_set_terrain)
	_resources.select_mode = ItemList.SELECT_MULTI
	_resources.allow_reselect = true
	_resources.custom_minimum_size.y = 112.0
	add_child(_labeled_control("Resources", _resources))
	_set_resources.text = "Set tile resources"
	add_child(_set_resources)
	_height.min_value = 0.0
	_height.max_value = 5.0
	_height.step = 1.0
	add_child(_labeled_control("Logical height", _height))
	_set_height.text = "Set tile height"
	add_child(_set_height)

func _apply_terrain() -> void:
	if not _can_edit() or _terrain.selected < 0:
		return
	var value := StringName(_terrain.get_item_metadata(_terrain.selected))
	await _begin_edit()
	_complete_edit(_editor.set_tile_terrain(_source, _coordinate(), value))

func _apply_resources() -> void:
	if not _can_edit():
		return
	var values: Array[StringName] = []
	for index in _resources.get_selected_items():
		values.append(StringName(_resources.get_item_metadata(index)))
	await _begin_edit()
	_complete_edit(_editor.set_tile_resources(_source, _coordinate(), values))

func _apply_height() -> void:
	if not _can_edit():
		return
	await _begin_edit()
	_complete_edit(_editor.set_tile_height(_source, _coordinate(), roundi(_height.value)))

func _begin_edit() -> void:
	_set_busy(true)
	status_changed.emit("Applying canonical logical map edit and recompiling Terrain3D…")
	await get_tree().process_frame

func _complete_edit(result: Dictionary) -> void:
	_set_busy(false)
	if not result["ok"]:
		error_raised.emit(result["message"])
		return
	_apply_snapshot(result["update"]["snapshot"])
	edit_persisted.emit(_source, _coordinate())

func _apply_snapshot(snapshot: Dictionary) -> void:
	_col.max_value = maxf(0.0, float(snapshot["cols"] - 1))
	_row.max_value = maxf(0.0, float(snapshot["rows"] - 1))
	_terrain.clear()
	var selected_terrain := 0
	for terrain_name in snapshot["terrainOptions"]:
		_terrain.add_item(str(terrain_name).capitalize())
		var terrain_index := _terrain.item_count - 1
		_terrain.set_item_metadata(terrain_index, terrain_name)
		if terrain_name == snapshot["tile"]["displayTerrain"]:
			selected_terrain = terrain_index
	_terrain.select(selected_terrain)
	_resources.clear()
	for resource_name in snapshot["resourceOptions"]:
		_resources.add_item(str(resource_name).capitalize())
		var resource_index := _resources.item_count - 1
		_resources.set_item_metadata(resource_index, resource_name)
		if resource_name in snapshot["tile"]["resources"]:
			_resources.select(resource_index, false)
	_height.set_value_no_signal(snapshot["tile"]["height"])

func _can_edit() -> bool:
	return _editor != null and _source != null and _editable

func _set_busy(busy: bool) -> void:
	_busy = busy
	_apply_enabled()

func _apply_enabled() -> void:
	var enabled := _can_edit() and not _busy
	_col.editable = enabled
	_row.editable = enabled
	_height.editable = enabled
	_terrain.disabled = not enabled
	_resources.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	_resources.modulate = Color.WHITE if enabled else Color(1.0, 1.0, 1.0, 0.5)
	for button in [_reload, _set_terrain, _set_resources, _set_height]:
		button.disabled = not enabled

func _coordinate() -> Vector2i:
	return Vector2i(roundi(_col.value), roundi(_row.value))

func _configure_coordinate(spin_box: SpinBox, tooltip: String) -> void:
	spin_box.min_value = 0.0
	spin_box.max_value = 0.0
	spin_box.step = 1.0
	spin_box.tooltip_text = tooltip
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _labeled_control(text: String, control: Control) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = text
	container.add_child(label)
	container.add_child(control)
	return container

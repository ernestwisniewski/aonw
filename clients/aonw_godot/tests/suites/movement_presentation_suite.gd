extends RefCounted

const PREVIEW_SCENE := "res://scenes/map_preview.tscn"

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_turn_action_guard()
	await _test_route_confirmation_and_evidence_animation()

func _test_turn_action_guard() -> void:
	var active := _turn(&"active", false, &"", &"ongoing")
	var pending := _turn(&"active", false, &"workerActionSelection", &"ongoing")
	var submitted := _turn(&"active", true, &"", &"ongoing")
	var finished := _turn(&"finished", false, &"", &"ongoing")
	var terminal := _turn(&"active", false, &"", &"conquest")
	_check(
		active.can_end_turn()
		and not pending.can_end_turn()
		and not submitted.can_end_turn()
		and not finished.can_end_turn()
		and not terminal.can_end_turn(),
		"Godot derives end-turn availability from recipient state, pending action, and outcome",
	)

func _turn(
	state: StringName,
	submitted: bool,
	pending_action: StringName,
	outcome: StringName,
) -> AonwLocalMatchViewModels.TurnView:
	var result := AonwLocalMatchViewModels.TurnView.new()
	result.has_own_state = true
	result.own_state = state
	result.own_submitted = submitted
	result.pending_action = pending_action
	result.outcome_condition = outcome
	return result

func _test_route_confirmation_and_evidence_animation() -> void:
	var packed := load(PREVIEW_SCENE) as PackedScene
	_check(packed != null, "Godot movement preview scene loads")
	if packed == null:
		return
	var screen := packed.instantiate() as Node3D
	Engine.get_main_loop().root.add_child(screen)
	await Engine.get_main_loop().process_frame
	var session: AonwLocalMatchWorkflow = screen.get("_local_match")
	var interaction: AonwMapInteractionController = screen.get_node("%MapInteraction")
	var unit_layer: AonwUnitLayer = screen.get_node("%UnitLayer")
	var confirm: Button = screen.get_node("%ConfirmMove")
	var end_turn: Button = screen.get_node("%EndTurn")
	var turn_status: Label = screen.get_node("%TurnStatus")
	var turn_hud: AonwTurnHud = screen.get_node("%TurnHud")
	for _frame in range(120):
		if (
			session.is_open()
			and unit_layer.unit_at(Vector2i(2, 1)) == "preview-commander"
		):
			break
		await Engine.get_main_loop().process_frame
	_check(
		session.is_open()
		and session.revision() == 0
		and unit_layer.unit_at(Vector2i(2, 1)) == "preview-commander"
		and not end_turn.disabled
		and turn_status.text.begins_with("Turn 1 · active"),
		"Godot preview opens the starter session asynchronously at revision zero",
	)

	interaction.set("_selected", Vector2i(2, 1))
	screen.call("_on_hex_selected", Vector2i(2, 1))
	for _frame in range(120):
		if screen.get("_reachable_hexes").has(Vector2i(2, 2)):
			break
		await Engine.get_main_loop().process_frame
	_check(
		screen.get("_reachable_hexes").has(Vector2i(2, 2)),
		"Godot resolves reachable movement without blocking the presentation thread",
	)
	interaction.set("_selected", Vector2i(2, 2))
	screen.call("_on_hex_selected", Vector2i(2, 2))
	for _frame in range(120):
		if screen.get("_route") != null:
			break
		await Engine.get_main_loop().process_frame
	var route: AonwLocalMatchViewModels.RouteView = screen.get("_route")
	var route_layer := screen.get_node("MapSurface/MapOverlay/Route") as MeshInstance3D
	_check(
		route != null
		and route.target == Vector2i(2, 2)
		and confirm.visible
		and route_layer.mesh != null,
		"Godot previews the Rust route and exposes explicit confirmation",
	)
	_check(
		session.revision() == 0
		and unit_layer.unit_at(Vector2i(2, 1)) == "preview-commander",
		"route preview does not mutate the canonical session",
	)
	var initial_marker := unit_layer.get_node_or_null("preview-commander") as MeshInstance3D
	var initial_mesh := initial_marker.mesh if initial_marker != null else null

	screen.call("_on_confirm_move_pressed")
	for _frame in range(120):
		if session.revision() == 1:
			break
		await Engine.get_main_loop().process_frame
	_check(session.revision() == 1, "Godot confirms movement through one revision-bound command")
	await Engine.get_main_loop().create_timer(0.5).timeout
	var marker := unit_layer.get_node_or_null("preview-commander") as MeshInstance3D
	var expected := interaction.projection().hex_center(Vector2i(2, 2), AonwUnitLayer.UNIT_OFFSET)
	_check(
		marker != null
		and marker == initial_marker
		and marker.mesh == initial_mesh
		and marker.position.is_equal_approx(expected)
		and unit_layer.unit_at(Vector2i(2, 1)).is_empty()
		and unit_layer.unit_at(Vector2i(2, 2)) == "preview-commander",
		"Godot applies the patch in place and updates its spatial unit index",
	)
	_check(
		not confirm.visible and screen.get("_route") == null,
		"accepted movement clears the route confirmation workflow",
	)
	var resynchronized: bool = await screen.call("_resync_projection")
	var resynchronized_marker := (
		unit_layer.get_node_or_null("preview-commander") as MeshInstance3D
	)
	_check(
		resynchronized
		and resynchronized_marker == marker
		and resynchronized_marker.mesh == initial_mesh
		and resynchronized_marker.position.is_equal_approx(expected),
		"snapshot resync reconciles stable unit IDs without rebuilding their nodes",
	)
	screen.call("_on_end_turn_pressed")
	for _frame in range(120):
		if session.revision() == 2:
			break
		await Engine.get_main_loop().process_frame
	var next_turn: AonwLocalMatchViewModels.TurnView = turn_hud.current()
	_check(
		session.revision() == 2
		and next_turn.number == 2
		and next_turn.can_end_turn()
		and not end_turn.disabled
		and turn_status.text.begins_with("Turn 2 · active · 0/1 submitted"),
		"Godot completes a real local turn without active-player or phase state",
	)
	interaction.set("_selected", Vector2i(2, 2))
	screen.set("_selected_unit_id", "preview-commander")
	screen.set("_reachable_hexes", {Vector2i(2, 1): true})
	session.close()
	_check(
		screen.get("_selected_unit_id").is_empty()
		and screen.get("_reachable_hexes").is_empty()
		and interaction.selected_hex() == AonwMapInteractionController.INVALID_HEX
		and unit_layer.unit_at(Vector2i(2, 2)).is_empty()
		and turn_hud.current() == null,
		"recipient invalidation clears owner-bound units, selection, routes, and turn state",
	)
	screen.free()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

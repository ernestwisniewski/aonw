extends RefCounted

const PREVIEW_SCENE := "res://scenes/map_preview.tscn"

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	await _test_route_confirmation_and_evidence_animation()

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
	_check(session.revision() == 0, "Godot preview opens the starter session at revision zero")

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
	session.close()
	screen.free()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

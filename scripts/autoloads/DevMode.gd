extends Node
## Developer mode autoload. Provides debug shortcuts for testing.
## Toggle dev mode on/off by pressing both thumbstick buttons simultaneously.
##
## [b]While dev mode is active:[/b][br]
## - Right thumbstick click: cycle to next spawn point[br]
## - Left thumbstick click: cycle to previous spawn point[br]
## - B button (right hand): skip current location (force complete)[br]
## - A button (right hand): toggle god mode (invincible)[br]
## - Left grip + Left trigger: spawn a test projectile aimed at you[br]
##
## Dev mode state is shown on the debug HUD when active.

## Emitted when dev mode is toggled on or off.
signal dev_mode_toggled(enabled: bool)

## Whether dev mode is currently active.
var enabled: bool = false

## God mode — player takes no damage.
var god_mode: bool = false

var _right_controller: XRController3D = null
var _left_controller: XRController3D = null
var _camera: XRCamera3D = null
var _spawn_points: Array[Marker3D] = []
var _current_spawn_index: int = 0


func _ready() -> void:
	# Wait a frame for the scene tree to be set up
	await get_tree().process_frame
	_find_controllers()

	# Re-find controllers when scenes change
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	# When XR rig loads, re-bind controllers
	if node is XRController3D:
		call_deferred("_find_controllers")


func _find_controllers() -> void:
	var origin := get_tree().get_first_node_in_group("player_body")
	if origin:
		var rig := origin.get_parent()
		_left_controller = rig.get_node_or_null("LeftController")
		_right_controller = rig.get_node_or_null("RightController")
		_camera = rig.get_node_or_null("XRCamera3D")

	# Disconnect old signals to avoid double-connects
	if _right_controller:
		if not _right_controller.button_pressed.is_connected(_on_right_button):
			_right_controller.button_pressed.connect(_on_right_button)
	if _left_controller:
		if not _left_controller.button_pressed.is_connected(_on_left_button):
			_left_controller.button_pressed.connect(_on_left_button)


func _on_right_button(action: String) -> void:
	# Toggle dev mode: both thumbstick clicks at once
	if action == "primary_click":
		if _left_controller and _left_controller.is_button_pressed("primary_click"):
			_toggle_dev_mode()
			return

	if not enabled:
		return

	match action:
		"primary_click":
			# Right thumbstick click: next spawn point
			_cycle_spawn_point(1)
		"by_button":
			# B button: force complete current location
			_force_complete_location()
		"ax_button":
			# A button: toggle god mode
			_toggle_god_mode()


func _on_left_button(action: String) -> void:
	# Toggle dev mode: both thumbstick clicks at once
	if action == "primary_click":
		if _right_controller and _right_controller.is_button_pressed("primary_click"):
			_toggle_dev_mode()
			return

	if not enabled:
		return

	match action:
		"primary_click":
			# Left thumbstick click: previous spawn point
			_cycle_spawn_point(-1)
		"trigger_click":
			# Left grip + trigger: spawn test projectile
			if _left_controller.get_float("grip") > 0.8:
				_spawn_test_projectile()


# ── Dev mode features ──

func _toggle_dev_mode() -> void:
	enabled = not enabled
	if enabled:
		_gather_spawn_points()
	print("[DevMode] %s" % ("ENABLED" if enabled else "DISABLED"))
	dev_mode_toggled.emit(enabled)


func _toggle_god_mode() -> void:
	god_mode = not god_mode
	print("[DevMode] God mode: %s" % ("ON" if god_mode else "OFF"))


func _cycle_spawn_point(direction: int) -> void:
	_gather_spawn_points()
	if _spawn_points.is_empty():
		print("[DevMode] No spawn points in scene")
		return

	_current_spawn_index = wrapi(_current_spawn_index + direction, 0, _spawn_points.size())
	var marker := _spawn_points[_current_spawn_index]
	_teleport_to(marker)
	print("[DevMode] Teleported to spawn point %d/%d (%s)" % [
		_current_spawn_index + 1, _spawn_points.size(), marker.name
	])


func _force_complete_location() -> void:
	print("[DevMode] Force completing location %d" % GameState.current_location)
	GameState.complete_location()


func _spawn_test_projectile() -> void:
	if not _camera:
		return
	var projectile_scene: PackedScene = load("res://scenes/core/Projectile.tscn")
	if not projectile_scene:
		print("[DevMode] Could not load Projectile.tscn")
		return

	var projectile: Node3D = projectile_scene.instantiate()
	# Fire at the player from 5m in front
	var forward := -_camera.global_transform.basis.z
	var spawn_pos := _camera.global_position + forward * 5.0
	var dir := (_camera.global_position - spawn_pos).normalized()

	projectile.set("color_id", GameState.ColorID.WHITE)
	projectile.call("set_direction", dir)
	projectile.set("speed", 4.0)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos
	print("[DevMode] Spawned test projectile")


func _teleport_to(marker: Marker3D) -> void:
	var xr_origin := get_tree().get_first_node_in_group("player_body")
	if xr_origin:
		xr_origin = xr_origin.get_parent()
	if not xr_origin:
		xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if not xr_origin:
		return
	xr_origin.global_position = marker.global_position
	xr_origin.global_rotation = marker.global_rotation


func _gather_spawn_points() -> void:
	_spawn_points.clear()
	var nodes := get_tree().get_nodes_in_group("spawn_points")
	for node in nodes:
		if node is Marker3D:
			_spawn_points.append(node)
	_spawn_points.sort_custom(func(a: Marker3D, b: Marker3D) -> bool:
		return a.name.naturalcasecmp_to(b.name) < 0
	)
	_current_spawn_index = clampi(_current_spawn_index, 0, maxi(_spawn_points.size() - 1, 0))

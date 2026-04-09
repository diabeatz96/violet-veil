extends XRController3D
## Drives combat behavior for each hand based on GameState.combat_mode.
## Attach to both LeftController and RightController.

## The projectile scene to fire in ABSORB_SHOOT mode (right hand).
@export var projectile_scene: PackedScene

## Projectile speed when fired from right hand.
@export var fire_speed: float = 8.0

## Fire pattern resource — controls spread, burst, ring, etc.
## Leave empty for a basic single shot.
@export var fire_pattern: FirePattern

## Which hand: 0 = LEFT, 1 = RIGHT
@export_enum("LEFT", "RIGHT") var side: int = 0

## Reference to the ReflectBarrier child node (set in _ready).
var _barrier: ReflectBarrier = null

## Absorb area for left hand in ABSORB_SHOOT mode.
var _absorb_area: Area3D = null

## Prevents overlapping burst coroutines.
var _is_firing: bool = false

func _ready() -> void:
	_barrier = get_node_or_null("ReflectBarrier")
	_absorb_area = get_node_or_null("AbsorbArea")
	button_pressed.connect(_on_button_pressed)
	GameState.mode_changed.connect(_on_mode_changed)
	_update_mode(GameState.combat_mode)

	# Left hand absorb area catches projectiles
	if _absorb_area and side == GameState.Side.LEFT:
		_absorb_area.body_entered.connect(_on_absorb_body_entered)


func _on_button_pressed(action: String) -> void:
	# X button on left hand toggles mode
	if action == "ax_button" and side == GameState.Side.LEFT:
		if GameState.combat_mode == GameState.Mode.REFLECT:
			GameState.combat_mode = GameState.Mode.ABSORB_SHOOT
		else:
			GameState.combat_mode = GameState.Mode.REFLECT

	# Right trigger fires in ABSORB_SHOOT mode
	if action == "trigger_click" and side == GameState.Side.RIGHT:
		if GameState.combat_mode == GameState.Mode.ABSORB_SHOOT:
			_fire_projectile()


func _on_mode_changed(_new_mode: int) -> void:
	_update_mode(_new_mode)


func _update_mode(mode: int) -> void:
	if mode == GameState.Mode.REFLECT:
		_enable_reflect()
	elif mode == GameState.Mode.ABSORB_SHOOT:
		_enable_absorb_shoot()


func _enable_reflect() -> void:
	if _barrier:
		_barrier.activate()
	if _absorb_area:
		_absorb_area.monitoring = false


func _enable_absorb_shoot() -> void:
	if _barrier:
		_barrier.deactivate()
	if _absorb_area and side == GameState.Side.LEFT:
		_absorb_area.monitoring = true


func _on_absorb_body_entered(body: Node3D) -> void:
	if GameState.combat_mode != GameState.Mode.ABSORB_SHOOT:
		return
	if not body.is_in_group("projectile"):
		return
	# Absorb the projectile's color into slot A
	var color_id: int = body.get("color_id") if body.get("color_id") != null else GameState.ColorID.NONE
	GameState.set_color_slot(GameState.Side.LEFT, color_id)
	body.queue_free()


func _fire_projectile() -> void:
	if not projectile_scene or _is_firing:
		return
	# Fire whatever color is in slot A (absorbed color)
	var color: int = GameState.color_slot_a
	if color == GameState.ColorID.NONE:
		return

	_is_firing = true
	var forward := -global_transform.basis.z
	var spawn_pos := global_position + (forward * 0.15)

	# If no pattern assigned, default to a single straight shot
	if not fire_pattern:
		_spawn_projectile(forward, spawn_pos, color)
	elif fire_pattern.is_burst():
		await _fire_burst(forward, spawn_pos, color)
	else:
		var directions: Array[Vector3] = fire_pattern.get_directions(forward)
		for dir in directions:
			_spawn_projectile(dir, spawn_pos, color)

	# Clear the slot after firing
	GameState.set_color_slot(GameState.Side.LEFT, GameState.ColorID.NONE)
	_is_firing = false


## Spawns a single projectile with the given direction, position, and color.
func _spawn_projectile(dir: Vector3, pos: Vector3, color: int) -> void:
	var projectile := projectile_scene.instantiate()
	var final_speed := fire_speed
	if fire_pattern:
		final_speed *= fire_pattern.speed_multiplier
		fire_pattern.apply_to_projectile(projectile)
	projectile.set("color_id", color)
	projectile.call("set_direction", dir)
	projectile.set("speed", final_speed)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = pos


## Fires projectiles one at a time with a delay between each.
func _fire_burst(forward: Vector3, pos: Vector3, color: int) -> void:
	for i in fire_pattern.projectile_count:
		if not is_inside_tree():
			return
		var dirs: Array[Vector3] = fire_pattern.get_directions(forward)
		_spawn_projectile(dirs[0], pos, color)
		if i < fire_pattern.projectile_count - 1:
			await get_tree().create_timer(fire_pattern.burst_delay).timeout

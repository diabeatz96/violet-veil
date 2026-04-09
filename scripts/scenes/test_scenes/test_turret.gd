extends Node3D
## Enemy turret that fires projectiles at the player's head on a timer.
## Place in any scene and configure via the inspector.
##
## [b]Usage:[/b] Assign a [member projectile_scene] and optionally a
## [member fire_pattern] to control spread, burst, homing, etc.
## The turret auto-aims at the XR camera each volley.
##
## [b]Color pool:[/b] Each shot picks a random color from [member color_pool].
## This determines the projectile tint and what color the player absorbs.

## Seconds between shots.
@export var fire_rate: float = 2.0

## Colors this turret picks from randomly.
@export var color_pool: Array[int] = [
	GameState.ColorID.WHITE,
	GameState.ColorID.BLUE,
]

## The projectile scene to instance.
@export var projectile_scene: PackedScene

## Fire pattern — controls spread, burst, ring, etc.
## Leave empty for a basic single shot.
@export var fire_pattern: FirePattern

## Projectile speed.
@export var projectile_speed: float = 5.0

var _timer: Timer
var _camera: XRCamera3D
var _is_firing: bool = false


func _ready() -> void:
	# Find the player camera to aim at
	var origin := get_tree().get_first_node_in_group("player_body")
	if origin:
		_camera = origin.get_parent().get_node_or_null("XRCamera3D")

	_timer = Timer.new()
	_timer.wait_time = fire_rate
	_timer.timeout.connect(_fire)
	add_child(_timer)
	_timer.start()


func _fire() -> void:
	if not projectile_scene or not _camera or _is_firing:
		return

	_is_firing = true

	# Pick a random color for this volley
	var color: int = GameState.ColorID.NONE
	if color_pool.size() > 0:
		color = color_pool[randi() % color_pool.size()]

	# Aim at the player's head
	var direction := (_camera.global_position - global_position).normalized()

	# No pattern — fire a single shot
	if not fire_pattern:
		_spawn_projectile(direction, color)
		_is_firing = false
		return

	# Wind-up delay — gives the player time to react
	if fire_pattern.windup_time > 0.0:
		await get_tree().create_timer(fire_pattern.windup_time).timeout
		if not is_inside_tree() or not _camera:
			_is_firing = false
			return
		# Re-aim after windup so direction is fresh
		direction = (_camera.global_position - global_position).normalized()

	# Burst fires over time
	if fire_pattern.is_burst():
		await _fire_burst(direction, color)
		_is_firing = false
		return

	# All other patterns fire instantly
	var directions: Array[Vector3] = fire_pattern.get_directions(direction)
	for dir in directions:
		_spawn_projectile(dir, color)

	_is_firing = false


func _spawn_projectile(dir: Vector3, color: int) -> void:
	var projectile: RigidBody3D = projectile_scene.instantiate()
	var final_speed := projectile_speed
	if fire_pattern:
		final_speed *= fire_pattern.speed_multiplier
		fire_pattern.apply_to_projectile(projectile, _camera)
	projectile.set("color_id", color)
	projectile.call("set_direction", dir)
	projectile.set("speed", final_speed)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position


func _fire_burst(direction: Vector3, color: int) -> void:
	for i in fire_pattern.projectile_count:
		if not is_inside_tree():
			return
		var dirs: Array[Vector3] = fire_pattern.get_directions(direction)
		_spawn_projectile(dirs[0], color)
		if i < fire_pattern.projectile_count - 1:
			await get_tree().create_timer(fire_pattern.burst_delay).timeout

extends Node3D
## Fires projectiles at the player at a configurable rate.
## Place in a test scene to test the reflect mechanic.

## Seconds between shots.
@export var fire_rate: float = 2.0

## Random spread in degrees for inaccuracy.
@export var spread_degrees: float = 3.0

## Colors this turret picks from randomly.
@export var color_pool: Array[int] = [
	GameState.ColorID.WHITE,
	GameState.ColorID.BLUE,
]

## The projectile scene to instance.
@export var projectile_scene: PackedScene

var _timer: Timer
var _camera: XRCamera3D

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
	if not projectile_scene or not _camera:
		return

	var projectile: RigidBody3D = projectile_scene.instantiate()

	# Pick a random color
	if color_pool.size() > 0:
		projectile.set("color_id", color_pool[randi() % color_pool.size()])

	# Calculate direction toward player head with optional spread
	var target_pos := _camera.global_position
	var direction := (target_pos - global_position).normalized()

	# Apply spread
	if spread_degrees > 0.0:
		var spread_rad := deg_to_rad(spread_degrees)
		direction = direction.rotated(Vector3.UP, randf_range(-spread_rad, spread_rad))
		direction = direction.rotated(Vector3.RIGHT, randf_range(-spread_rad, spread_rad))

	projectile.call("set_direction", direction)

	# Add to tree FIRST, then set position (fixes global_transform error)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position

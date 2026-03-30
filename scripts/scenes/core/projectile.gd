class_name Projectile
extends RigidBody3D
## A color-tagged projectile that moves in a straight line.
## Add to the "projectile" group. Detectable by ReflectBarrier.

## The color this projectile carries.
@export_enum("NONE", "WHITE", "BLUE", "RED", "AMBER", "VIOLET", "PALE_BLUE", "TEAL", "DEEP_ORANGE") var color_id: int = GameState.ColorID.NONE

## Movement speed in meters per second.
@export var speed: float = 5.0

## Seconds before auto-despawn.
@export var lifetime: float = 5.0

## Damage multiplier (set by FirePattern).
var damage_multiplier: float = 1.0

## Acceleration in m/s² — positive speeds up, negative slows down.
var acceleration: float = 0.0

## How strongly this projectile curves toward its homing target.
var homing_strength: float = 0.0

## Seconds before homing activates.
var homing_delay: float = 0.0

## The node this projectile homes toward (usually the player camera).
var homing_target: Node3D = null

var _direction: Vector3 = Vector3.FORWARD
var _reflected: bool = false
var _current_speed: float = 0.0
var _homing_timer: float = 0.0
var _alive_time: float = 0.0

func _ready() -> void:
	add_to_group("projectile")
	gravity_scale = 0.0
	freeze = false
	contact_monitor = true
	max_contacts_reported = 1
	linear_damp = 0.0
	body_entered.connect(_on_body_entered)

	_current_speed = speed

	# Apply initial velocity
	linear_velocity = _direction * _current_speed

	# Auto-despawn timer
	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

	# Tint the mesh to match color
	_apply_color_tint()


func _physics_process(delta: float) -> void:
	_alive_time += delta

	# Acceleration — speed up or slow down over time
	if acceleration != 0.0:
		_current_speed = maxf(0.5, _current_speed + acceleration * delta)

	# Homing — steer toward target after the delay
	if homing_strength > 0.0 and homing_target and is_instance_valid(homing_target):
		_homing_timer += delta
		if _homing_timer >= homing_delay:
			var to_target := (homing_target.global_position - global_position).normalized()
			_direction = _direction.lerp(to_target, homing_strength * delta).normalized()

	# Apply updated velocity
	linear_velocity = _direction * _current_speed


## Called by ReflectBarrier to reverse direction back toward where it came from.
func reflect(barrier_normal: Vector3) -> void:
	if _reflected:
		return
	_reflected = true
	# Reverse direction so it goes back toward the shooter
	_direction = -_direction
	linear_velocity = _direction * _current_speed
	# Kill homing so reflected projectiles fly straight back
	homing_strength = 0.0
	homing_target = null


## Set direction before adding to scene tree.
func set_direction(dir: Vector3) -> void:
	_direction = dir.normalized()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("projectile"):
		return
	if body is ReflectBarrier:
		return
	queue_free()


func _apply_color_tint() -> void:
	var mesh_instance := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if not mesh_instance:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_color_for_id(color_id)
	mat.emission_enabled = true
	mat.emission = _get_color_for_id(color_id)
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat


func _get_color_for_id(id: int) -> Color:
	match id:
		GameState.ColorID.WHITE: return Color.WHITE
		GameState.ColorID.BLUE: return Color(0.2, 0.4, 1.0)
		GameState.ColorID.RED: return Color(1.0, 0.15, 0.15)
		GameState.ColorID.AMBER: return Color(1.0, 0.75, 0.0)
		GameState.ColorID.VIOLET: return Color(0.58, 0.0, 0.83)
		GameState.ColorID.PALE_BLUE: return Color(0.6, 0.8, 1.0)
		GameState.ColorID.TEAL: return Color(0.0, 0.8, 0.7)
		GameState.ColorID.DEEP_ORANGE: return Color(1.0, 0.4, 0.0)
		_: return Color(0.5, 0.5, 0.5)

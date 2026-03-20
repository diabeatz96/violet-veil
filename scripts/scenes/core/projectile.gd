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

var _direction: Vector3 = Vector3.FORWARD
var _reflected: bool = false

func _ready() -> void:
	add_to_group("projectile")
	gravity_scale = 0.0
	freeze = false
	contact_monitor = true
	max_contacts_reported = 1
	linear_damp = 0.0
	body_entered.connect(_on_body_entered)

	# Apply initial velocity
	linear_velocity = _direction * speed

	# Auto-despawn timer
	var timer := Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

	# Tint the mesh to match color
	_apply_color_tint()


## Called by ReflectBarrier to reverse direction back toward where it came from.
func reflect(barrier_normal: Vector3) -> void:
	if _reflected:
		return
	_reflected = true
	# Simply reverse direction so it goes back toward the shooter
	_direction = -_direction
	linear_velocity = _direction * speed


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

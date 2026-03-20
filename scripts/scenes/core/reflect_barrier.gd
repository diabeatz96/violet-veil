class_name ReflectBarrier
extends Area3D
## Reflects incoming projectiles back when active.
## Attach as a child of each XRController3D (via HandController).

signal projectile_reflected(color_id: int)

## Whether the barrier is currently active.
var _active: bool = true

func _ready() -> void:
	monitoring = _active
	monitorable = false
	body_entered.connect(_on_body_entered)


func activate() -> void:
	_active = true
	monitoring = true


func deactivate() -> void:
	_active = false
	monitoring = false


func _on_body_entered(body: Node3D) -> void:
	if not _active:
		return
	if not body.is_in_group("projectile"):
		return
	if not body.has_method("reflect"):
		return
	var color_id: int = body.get("color_id") if body.get("color_id") != null else GameState.ColorID.NONE
	body.call("reflect", global_transform.basis.z.normalized())
	projectile_reflected.emit(color_id)

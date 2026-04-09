class_name ReflectBarrier
extends Area3D
## Reflects incoming projectiles back toward the shooter.
## Attach as a child of each XRController3D (via HandController).
##
## Active in [code]REFLECT[/code] mode. When a body in the
## [code]"projectile"[/code] group enters, it calls [method Projectile.reflect]
## to reverse direction and emits [signal projectile_reflected].
##
## [b]Collision setup:[/b] collision_layer = 0, collision_mask = layer 2
## (projectiles should be on layer 2).

## Emitted when a projectile is reflected. Passes the projectile's [member Projectile.color_id].
signal projectile_reflected(color_id: int)

## Whether the barrier is currently active.
var _active: bool = true

func _ready() -> void:
	monitoring = _active
	monitorable = false
	body_entered.connect(_on_body_entered)


## Enable the barrier. Called by HandController when entering REFLECT mode.
func activate() -> void:
	_active = true
	monitoring = true


## Disable the barrier. Called by HandController when entering ABSORB_SHOOT mode.
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

class_name FirePattern
extends Resource
## Defines how projectiles are fired: count, spread, timing, and behavior.
## Create [code].tres[/code] files from this resource in the inspector
## and assign them to turrets or the player's hand controller.
##
## [b]Presets[/b] are in [code]res://resources/fire_patterns/[/code]:[br]
## - [code]single.tres[/code] — one straight shot[br]
## - [code]spread.tres[/code] — 5-projectile fan (shotgun)[br]
## - [code]burst.tres[/code] — 3 rapid shots[br]
## - [code]ring.tres[/code] — 8 projectiles in a circle[br]
## - [code]homing.tres[/code] — slow, large, curves toward the player[br]
##
## [b]To create a new pattern:[/b] Right-click in FileSystem → New Resource →
## FirePattern. Tweak values in the inspector.

## The shape of the fire pattern.
enum Shape {
	SINGLE,  ## One projectile straight ahead.
	SPREAD,  ## Fan of projectiles (shotgun style).
	BURST,   ## Rapid-fire sequence of shots in a line.
	RING,    ## Circle of projectiles outward from center.
}

## Which pattern shape to use.
@export var shape: Shape = Shape.SINGLE

## How many projectiles per shot. SINGLE ignores this (always 1).
@export_range(1, 20) var projectile_count: int = 1

## Total fan angle in degrees for SPREAD, or ignored for others.
@export_range(0.0, 180.0) var spread_angle_degrees: float = 30.0

## Seconds between each projectile in a BURST.
@export_range(0.01, 1.0) var burst_delay: float = 0.1

## Random angle offset added to each projectile for inaccuracy.
@export_range(0.0, 15.0) var accuracy_jitter_degrees: float = 0.0

## Speed multiplier applied to each projectile (1.0 = normal speed).
@export_range(0.1, 5.0) var speed_multiplier: float = 1.0

# ── Projectile Properties ──

## Damage multiplier per projectile (1.0 = normal). Lower for shotgun, higher for sniper.
@export_group("Projectile Properties")
@export_range(0.1, 5.0) var damage_multiplier: float = 1.0

## Scale of each projectile mesh. Bigger = easier to see and reflect.
@export_range(0.2, 3.0) var projectile_scale: float = 1.0

## Override projectile lifetime in seconds. 0 = use the projectile's default.
@export_range(0.0, 15.0) var lifetime_override: float = 0.0

## Acceleration in m/s². Positive = speeds up, negative = slows down, 0 = constant.
@export_range(-10.0, 10.0) var acceleration: float = 0.0

# ── Homing ──

## How strongly projectiles curve toward the target. 0 = no homing.
@export_group("Homing")
@export_range(0.0, 10.0) var homing_strength: float = 0.0

## Delay before homing kicks in. Gives the player a moment to read the trajectory.
@export_range(0.0, 3.0) var homing_delay: float = 0.0

# ── Wind-up ──

## Seconds of telegraph before the volley fires. 0 = instant.
## Use this to give the player time to raise their barrier.
@export_group("Wind-up")
@export_range(0.0, 3.0) var windup_time: float = 0.0


## Applies this pattern's properties (damage, scale, homing, etc.) to a projectile.
## Call this after instantiating but before adding to the scene tree.
func apply_to_projectile(projectile: Node3D, homing_target: Node3D = null) -> void:
	projectile.set("damage_multiplier", damage_multiplier)
	projectile.set("acceleration", acceleration)

	if lifetime_override > 0.0:
		projectile.set("lifetime", lifetime_override)

	if projectile_scale != 1.0:
		projectile.scale = Vector3.ONE * projectile_scale

	if homing_strength > 0.0 and homing_target:
		projectile.set("homing_strength", homing_strength)
		projectile.set("homing_delay", homing_delay)
		projectile.set("homing_target", homing_target)


## Returns a list of direction vectors for this pattern.
## [param forward] is the base aim direction (normalized).
## For BURST, this returns one direction per call — the caller handles the loop and delay.
func get_directions(forward: Vector3) -> Array[Vector3]:
	forward = forward.normalized()
	var directions: Array[Vector3] = []

	match shape:
		Shape.SINGLE:
			directions.append(_jitter(forward))

		Shape.SPREAD:
			directions = _build_spread(forward)

		Shape.BURST:
			# Burst fires one at a time, so each call returns a single direction.
			directions.append(_jitter(forward))

		Shape.RING:
			directions = _build_ring(forward)

	return directions


## Returns true if this pattern fires over time (needs a coroutine).
func is_burst() -> bool:
	return shape == Shape.BURST and projectile_count > 1


# ── Private helpers ──

func _build_spread(forward: Vector3) -> Array[Vector3]:
	var dirs: Array[Vector3] = []
	if projectile_count <= 1:
		dirs.append(_jitter(forward))
		return dirs

	# Spread evenly across the fan angle
	var half_angle := deg_to_rad(spread_angle_degrees) / 2.0
	var step := deg_to_rad(spread_angle_degrees) / (projectile_count - 1)

	# Pick an axis perpendicular to forward for rotating
	var up := Vector3.UP
	if abs(forward.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right := forward.cross(up).normalized()

	for i in projectile_count:
		var angle := -half_angle + step * i
		var dir := forward.rotated(right, angle)
		dirs.append(_jitter(dir))

	return dirs


func _build_ring(forward: Vector3) -> Array[Vector3]:
	var dirs: Array[Vector3] = []
	if projectile_count <= 1:
		dirs.append(_jitter(forward))
		return dirs

	# Rotate around the forward axis in a full circle
	var angle_step := TAU / projectile_count

	# We need a vector perpendicular to forward as our starting offset
	var up := Vector3.UP
	if abs(forward.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var perp := forward.cross(up).normalized()

	# Each projectile goes outward from the ring, angled slightly forward
	for i in projectile_count:
		var ring_dir := perp.rotated(forward, angle_step * i)
		# Mix forward direction with ring direction (70% forward, 30% outward)
		var final_dir := (forward * 0.7 + ring_dir * 0.3).normalized()
		dirs.append(_jitter(final_dir))

	return dirs


func _jitter(dir: Vector3) -> Vector3:
	if accuracy_jitter_degrees <= 0.0:
		return dir.normalized()

	var jitter_rad := deg_to_rad(accuracy_jitter_degrees)
	var up := Vector3.UP
	if abs(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT

	dir = dir.rotated(up, randf_range(-jitter_rad, jitter_rad))
	var right := dir.cross(up).normalized()
	dir = dir.rotated(right, randf_range(-jitter_rad, jitter_rad))
	return dir.normalized()

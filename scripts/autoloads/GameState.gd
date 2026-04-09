extends Node
## Global game state autoload. Single source of truth for player stats,
## combat mode, color slots, and progression tracking.
##
## Other systems read and write to this node directly:[br]
## - [b]HandController[/b] reads [member combat_mode] and [member color_slot_a].[br]
## - [b]LevelManager[/b] listens to [signal sublevel_cleared] and [signal location_cleared].[br]
## - UI can bind to any signal to update HUD elements.[br]
##
## @tutorial: Call [method complete_location] when all enemies at a spawn point
## are defeated. Call [method complete_sublevel] only if you need to skip
## the location system (LevelManager calls it automatically).

# ── Enums ──

## All projectile / slot color types. NONE means empty.
enum ColorID { NONE, WHITE, BLUE, RED, AMBER, VIOLET, PALE_BLUE, TEAL, DEEP_ORANGE }

## Player combat modes — toggled by the left hand X button.
enum Mode { REFLECT, ABSORB_SHOOT }

## Effect categories that colors may map to in the future.
enum EffectType { DAMAGE, SLOW, AREA_DENIAL, BURST_DAMAGE, MAJOR_DAMAGE }

## Which hand: LEFT = 0, RIGHT = 1.
enum Side { LEFT, RIGHT }

# ── Signals ──

## Emitted when [member color_slot_a] (left hand) changes.
signal slot_a_changed(color_id: int)

## Emitted when [member color_slot_b] (right hand) changes.
signal slot_b_changed(color_id: int)

## Emitted when [member combat_mode] changes between REFLECT and ABSORB_SHOOT.
signal mode_changed(mode: int)

## Emitted when the player takes a hit. Passes the new [member player_hp].
signal player_hit(current_hp: int)

## Emitted when a sub-level is completed. LevelManager listens to this
## to load the next sub-level scene or advance the tier.
signal sublevel_cleared(tier: int, sublevel: int)

## Emitted when all enemies at the current location are defeated.
## LevelManager listens to this to teleport the player to the next spawn point.
signal location_cleared(tier: int, sublevel: int, location: int)

# ── State ──

## Current tier (1 = Upper Veil, 2 = Mid Veil, 3 = Lower Veil).
var current_tier: int = 1

## Current sub-level within the tier (1-3: combat_1, combat_2, boss).
var current_sublevel: int = 1

## Current location (spawn point index) within the sub-level. Starts at 0.
var current_location: int = 0

## Player health points. Starts at 100.
var player_hp: int = 100

## Total number of hits taken this session.
var hit_count: int = 0

## Color held in the left hand slot. Set via [method set_color_slot].
var color_slot_a: int = ColorID.NONE:
	set(value):
		color_slot_a = value
		slot_a_changed.emit(value)

## Color held in the right hand slot. Set via [method set_color_slot].
var color_slot_b: int = ColorID.NONE:
	set(value):
		color_slot_b = value
		slot_b_changed.emit(value)

## Active combat mode. Setting this emits [signal mode_changed].
var combat_mode: int = Mode.REFLECT:
	set(value):
		combat_mode = value
		mode_changed.emit(value)

# ── Methods ──

## Register a hit on the player. Increments [member hit_count], decreases
## [member player_hp] by 1, and emits [signal player_hit].
## Blocked when [member DevMode.god_mode] is active.
func register_hit() -> void:
	var dev_mode := get_node_or_null("/root/DevMode")
	if dev_mode and dev_mode.get("god_mode"):
		return
	hit_count += 1
	player_hp -= 1
	player_hit.emit(player_hp)


## Set the color for a hand slot. Pass [enum Side].LEFT or [enum Side].RIGHT.
## Emits [signal slot_a_changed] or [signal slot_b_changed].
func set_color_slot(side: int, id: int) -> void:
	if side == Side.LEFT:
		color_slot_a = id
	else:
		color_slot_b = id


## Reset both color slots to NONE.
func clear_slots() -> void:
	color_slot_a = ColorID.NONE
	color_slot_b = ColorID.NONE


## Call when all enemies at the current location are defeated.
## Emits [signal location_cleared]. LevelManager will handle the teleport
## to the next spawn point or trigger [method complete_sublevel] automatically.
func complete_location() -> void:
	location_cleared.emit(current_tier, current_sublevel, current_location)


## Call to mark the current sub-level as complete.
## Emits [signal sublevel_cleared]. LevelManager will load the next scene.
## [b]Note:[/b] You usually don't need to call this directly — LevelManager
## calls it automatically when all locations in a sub-level are cleared.
func complete_sublevel() -> void:
	sublevel_cleared.emit(current_tier, current_sublevel)

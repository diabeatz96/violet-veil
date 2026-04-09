extends Node
## Manages tier / sub-level / location progression and scene transitions.
## Registered as an autoload — access globally via [code]LevelManager[/code].
##
## [b]Progression hierarchy:[/b][br]
## [code]Tier → Sub-level (scene change) → Locations (teleport within scene)[/code][br]
##
## [b]How it works:[/b][br]
## 1. Call [method start_game] to begin at tier 1.[br]
## 2. Each sub-level scene has [Marker3D] nodes in the [code]"spawn_points"[/code] group.[br]
## 3. When enemies are cleared at a location, call [method GameState.complete_location].[br]
## 4. LevelManager teleports to the next spawn point automatically.[br]
## 5. When all locations are done, it loads the next sub-level scene.[br]
## 6. When all sub-levels are done, it advances the tier.[br]
## 7. When all tiers are done, [signal game_completed] fires.[br]
##
## [b]Debugging:[/b] Use [method go_to_sublevel] to jump to any tier/sublevel.

# ── Signals ──

## Emitted when a scene transition or teleport begins. Use this to disable
## player input, pause enemies, etc.
signal transition_started

## Emitted when the transition finishes and gameplay should resume.
signal transition_finished

## Emitted after the player teleports to a new location within a sub-level.
signal location_changed(location_index: int)

## Emitted when a new sub-level scene is loaded and the player is placed.
signal sublevel_started(tier: int, sublevel: int)

## Emitted when all 3 sub-levels in a tier are completed.
signal tier_completed(tier: int)

## Emitted when all tiers are completed. Hook this up to your victory screen.
signal game_completed

# ── Constants ──

const TIERS := {
	1: {
		"name": "Upper Veil",
		"sublevels": [
			"res://scenes/levels/upper_veil/combat_1.tscn",
			"res://scenes/levels/upper_veil/combat_2.tscn",
			"res://scenes/levels/upper_veil/boss.tscn",
		],
	},
	2: {
		"name": "Mid Veil",
		"sublevels": [
			"res://scenes/levels/mid_veil/combat_1.tscn",
			"res://scenes/levels/mid_veil/combat_2.tscn",
			"res://scenes/levels/mid_veil/boss.tscn",
		],
	},
	3: {
		"name": "Lower Veil",
		"sublevels": [
			"res://scenes/levels/lower_veil/combat_1.tscn",
			"res://scenes/levels/lower_veil/combat_2.tscn",
			"res://scenes/levels/lower_veil/boss.tscn",
		],
	},
}

const SUBLEVELS_PER_TIER := 3
const TOTAL_TIERS := 3

# ── State ──

## The active transition effect. Set by _find_transition() on scene load.
var _transition: TransitionEffect = null

## Sorted list of Marker3D spawn points in the current scene.
var _spawn_points: Array[Marker3D] = []

## Whether we're currently mid-transition (prevents double-triggers).
var _transitioning: bool = false


func _ready() -> void:
	GameState.location_cleared.connect(_on_location_cleared)
	GameState.sublevel_cleared.connect(_on_sublevel_cleared)


# ── Public API ──

## Start the game from tier 1, sublevel 1, location 0.
func start_game() -> void:
	GameState.current_tier = 1
	GameState.current_sublevel = 1
	GameState.current_location = 0
	_load_current_sublevel()


## Jump to a specific tier and sublevel. Useful for debugging / level select.
func go_to_sublevel(tier: int, sublevel: int) -> void:
	GameState.current_tier = tier
	GameState.current_sublevel = sublevel
	GameState.current_location = 0
	_load_current_sublevel()


## Teleport the player to a specific location index in the current scene.
func go_to_location(index: int) -> void:
	if index < 0 or index >= _spawn_points.size():
		push_warning("LevelManager: location index %d out of range (have %d)" % [index, _spawn_points.size()])
		return
	GameState.current_location = index
	await _teleport_player_to(_spawn_points[index])
	location_changed.emit(index)


# ── Signal handlers ──

func _on_location_cleared(_tier: int, _sublevel: int, location: int) -> void:
	var next_location := location + 1
	if next_location < _spawn_points.size():
		# More locations in this sub-level — teleport
		go_to_location(next_location)
	else:
		# All locations done — complete the sub-level
		GameState.complete_sublevel()


func _on_sublevel_cleared(tier: int, sublevel: int) -> void:
	if _transitioning:
		return

	var next_sublevel := sublevel + 1
	if next_sublevel <= SUBLEVELS_PER_TIER:
		# More sub-levels in this tier
		GameState.current_sublevel = next_sublevel
		GameState.current_location = 0
		_load_current_sublevel()
	else:
		# Tier complete
		tier_completed.emit(tier)
		var next_tier := tier + 1
		if next_tier <= TOTAL_TIERS:
			GameState.current_tier = next_tier
			GameState.current_sublevel = 1
			GameState.current_location = 0
			_load_current_sublevel()
		else:
			game_completed.emit()


# ── Scene loading ──

func _load_current_sublevel() -> void:
	var tier: int = GameState.current_tier
	var sublevel: int = GameState.current_sublevel

	if not TIERS.has(tier):
		push_error("LevelManager: invalid tier %d" % tier)
		return

	var sublevel_index := sublevel - 1
	var paths: Array = TIERS[tier]["sublevels"]
	if sublevel_index < 0 or sublevel_index >= paths.size():
		push_error("LevelManager: invalid sublevel %d for tier %d" % [sublevel, tier])
		return

	var scene_path: String = paths[sublevel_index]
	_transitioning = true
	transition_started.emit()

	# Fade out
	_find_transition()
	if _transition:
		await _transition.fade_out()

	# Change scene
	get_tree().change_scene_to_file(scene_path)

	# Wait one frame for the new scene to be ready
	await get_tree().process_frame

	# Gather spawn points and teleport player to location 0
	_gather_spawn_points()
	GameState.current_location = 0
	if _spawn_points.size() > 0:
		_teleport_player_to_instant(_spawn_points[0])

	# Fade in
	_find_transition()
	if _transition:
		await _transition.fade_in()

	_transitioning = false
	sublevel_started.emit(tier, sublevel)
	transition_finished.emit()


# ── Teleportation ──

## Teleport with transition effect (for in-scene location changes).
func _teleport_player_to(marker: Marker3D) -> void:
	_transitioning = true
	transition_started.emit()

	_find_transition()
	if _transition:
		await _transition.fade_out()

	_teleport_player_to_instant(marker)

	if _transition:
		await _transition.fade_in()

	_transitioning = false
	transition_finished.emit()


## Move the XR origin to match the marker's position instantly.
func _teleport_player_to_instant(marker: Marker3D) -> void:
	var xr_origin := get_tree().get_first_node_in_group("player_body")
	if xr_origin:
		# player_body is a child of XROrigin3D — move the origin
		xr_origin = xr_origin.get_parent()
	else:
		# Fallback: look for XROrigin3D directly
		xr_origin = get_tree().get_first_node_in_group("xr_origin")

	if not xr_origin:
		push_warning("LevelManager: no XR origin found to teleport")
		return

	xr_origin.global_position = marker.global_position
	xr_origin.global_rotation = marker.global_rotation


# ── Helpers ──

## Find all Marker3D nodes in the "spawn_points" group, sorted by name.
func _gather_spawn_points() -> void:
	_spawn_points.clear()
	var nodes := get_tree().get_nodes_in_group("spawn_points")
	for node in nodes:
		if node is Marker3D:
			_spawn_points.append(node)
	# Sort by name so spawn_1, spawn_2, spawn_3 are in order
	_spawn_points.sort_custom(func(a: Marker3D, b: Marker3D) -> bool:
		return a.name.naturalcasecmp_to(b.name) < 0
	)


## Look for a TransitionEffect in the scene tree.
func _find_transition() -> void:
	var node := get_tree().get_first_node_in_group("transition_effect")
	if node is TransitionEffect:
		_transition = node
	else:
		_transition = null

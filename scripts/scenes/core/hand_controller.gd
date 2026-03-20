extends XRController3D
## Drives combat behavior for each hand based on GameState.combat_mode.
## Attach to both LeftController and RightController.

## Which hand: 0 = LEFT, 1 = RIGHT
@export_enum("LEFT", "RIGHT") var side: int = 0

## Reference to the ReflectBarrier child node (set in _ready).
var _barrier: Node = null

func _ready() -> void:
	_barrier = get_node_or_null("ReflectBarrier")
	button_pressed.connect(_on_button_pressed)
	GameState.mode_changed.connect(_on_mode_changed)
	_update_mode(GameState.combat_mode)


func _on_button_pressed(action: String) -> void:
	# X button on left hand toggles mode (ax_button from godot action set)
	if action == "ax_button" and side == GameState.Side.LEFT:
		if GameState.combat_mode == GameState.Mode.REFLECT:
			GameState.combat_mode = GameState.Mode.ABSORB_SHOOT
		else:
			GameState.combat_mode = GameState.Mode.REFLECT


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


func _enable_absorb_shoot() -> void:
	if _barrier:
		_barrier.deactivate()

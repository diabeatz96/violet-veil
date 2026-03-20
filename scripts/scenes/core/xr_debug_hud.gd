extends Node3D
## Wrist-mounted debug HUD. Attach as a child of LeftController.
## Always visible for now.

@onready var label: Label3D = $Label3D

var _left: XRController3D
var _right: XRController3D

func _ready() -> void:
	var origin := get_parent().get_parent()
	_left = origin.get_node_or_null("LeftController")
	_right = origin.get_node_or_null("RightController")
	visible = true

	if _left:
		_left.button_pressed.connect(_on_any_button.bind("L_pressed"))
		_left.button_released.connect(_on_any_button.bind("L_released"))
	if _right:
		_right.button_pressed.connect(_on_any_button.bind("R_pressed"))
		_right.button_released.connect(_on_any_button.bind("R_released"))


func _on_any_button(action: String, source: String) -> void:
	print("[DebugHUD] %s: %s" % [source, action])


func _process(_delta: float) -> void:
	if not label:
		return

	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== VV Debug ===")
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	lines.append("Mode: %s" % GameState.Mode.keys()[GameState.combat_mode])
	lines.append("SlotA: %s" % GameState.ColorID.keys()[GameState.color_slot_a])
	lines.append("SlotB: %s" % GameState.ColorID.keys()[GameState.color_slot_b])
	lines.append("HP: %d  Hits: %d" % [GameState.player_hp, GameState.hit_count])
	lines.append("")

	if _left:
		lines.append("L active: %s" % str(_left.get_is_active()))
		lines.append("L trigger: %.2f" % _left.get_float("trigger"))
		lines.append("L grip: %.2f" % _left.get_float("grip"))
		lines.append("L ax(X): %s" % str(_left.is_button_pressed("ax_button")))
		lines.append("L by(Y): %s" % str(_left.is_button_pressed("by_button")))

	if _right:
		lines.append("R active: %s" % str(_right.get_is_active()))
		lines.append("R trigger: %.2f" % _right.get_float("trigger"))
		lines.append("R grip: %.2f" % _right.get_float("grip"))
		lines.append("R ax(A): %s" % str(_right.is_button_pressed("ax_button")))
		lines.append("R by(B): %s" % str(_right.is_button_pressed("by_button")))

	label.text = "\n".join(lines)

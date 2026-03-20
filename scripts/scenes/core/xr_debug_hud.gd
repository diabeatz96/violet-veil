extends Node3D
## Wrist-mounted debug HUD. Attach as a child of LeftController.
## Toggle visibility with Y button (left hand).

@onready var label: Label3D = $Label3D

var _left: XRController3D
var _right: XRController3D
var _hud_visible: bool = false

func _ready() -> void:
	var origin := get_parent().get_parent()
	_left = origin.get_node_or_null("LeftController")
	_right = origin.get_node_or_null("RightController")
	visible = false
	if _left:
		_left.button_pressed.connect(_on_button_pressed)


func _on_button_pressed(action: String) -> void:
	if action == "by_button":
		_hud_visible = not _hud_visible
		visible = _hud_visible


func _process(_delta: float) -> void:
	if not visible or not label:
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
		var mt := _left.is_button_pressed("mode_toggle")
		var ab := _left.get_float("absorb")
		var gl := _left.get_float("grip_left")
		lines.append("L toggle: %s" % str(mt))
		lines.append("L absorb: %.2f" % ab)
		lines.append("L grip:   %.2f" % gl)

	if _right:
		var fi := _right.get_float("fire")
		var gr := _right.get_float("grip_right")
		lines.append("R fire:   %.2f" % fi)
		lines.append("R grip:   %.2f" % gr)

	label.text = "\n".join(lines)

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
	lines.append("Tier: %d  Sub: %d  Loc: %d" % [GameState.current_tier, GameState.current_sublevel, GameState.current_location])

	var dev_mode := get_node_or_null("/root/DevMode")
	if dev_mode and dev_mode.enabled:
		lines.append("")
		lines.append("=== DEV MODE ===")
		lines.append("God: %s" % ("ON" if dev_mode.god_mode else "OFF"))
		var spawn_count: int = dev_mode.get_spawn_count()
		if spawn_count > 0:
			lines.append("Spawn: %d/%d" % [dev_mode.get_spawn_index() + 1, spawn_count])
		else:
			lines.append("Spawn: none")
		lines.append("")
		lines.append("R-stick: next spawn")
		lines.append("L-stick: prev spawn")
		lines.append("A: god mode")
		lines.append("B: skip location")
		lines.append("L-grip+trig: test proj")
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

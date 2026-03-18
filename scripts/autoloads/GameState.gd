extends Node

# ── Enums ──

enum ColorID { NONE, WHITE, BLUE, RED, AMBER, VIOLET, PALE_BLUE, TEAL, DEEP_ORANGE } # This finna contain all our color combinations
enum Mode { REFLECT, ABSORB_SHOOT }
enum EffectType { DAMAGE, SLOW, AREA_DENIAL, BURST_DAMAGE, MAJOR_DAMAGE } # Eventually this will contain our effects for each color
enum Side { LEFT, RIGHT }

# ── Signals ──

signal slot_a_changed(color_id: ColorID)
signal slot_b_changed(color_id: ColorID)
signal mode_changed(mode: Mode)
signal player_hit(current_hp: int)
signal sublevel_cleared(tier: int, sublevel: int)

# ── State ──

var current_tier: int = 1
var current_sublevel: int = 1
var player_hp: int = 100
var hit_count: int = 0

var color_slot_a: ColorID = ColorID.NONE:
	set(value):
		color_slot_a = value
		slot_a_changed.emit(value)

var color_slot_b: ColorID = ColorID.NONE:
	set(value):
		color_slot_b = value
		slot_b_changed.emit(value)

var combat_mode: Mode = Mode.REFLECT:
	set(value):
		combat_mode = value
		mode_changed.emit(value)

# ── Methods ──

func register_hit() -> void:
	hit_count += 1
	player_hp -= 1 ## Eventually we will figure out wha to do with health, temporary health solution
	player_hit.emit(player_hp)


func set_color_slot(side: Side, id: ColorID) -> void:
	if side == Side.LEFT:
		color_slot_a = id
	else:
		color_slot_b = id


func clear_slots() -> void:
	color_slot_a = ColorID.NONE
	color_slot_b = ColorID.NONE


func complete_sublevel() -> void:
	sublevel_cleared.emit(current_tier, current_sublevel)

class_name FadeTransition
extends TransitionEffect
## Simple fade-to-black transition for VR. Extends [TransitionEffect].
##
## [b]Scene setup:[/b] Add a [ColorRect] as a child node named
## [code]ColorRect[/code]. It should cover the full viewport (or be a
## world-space quad parented to the XR camera for VR).
## This node auto-registers in the [code]"transition_effect"[/code] group.
##
## Customize [member fade_duration] and [member fade_color] in the inspector.

## How long the fade takes in seconds.
@export var fade_duration: float = 0.4

## The color to fade to.
@export var fade_color: Color = Color.BLACK

@onready var _color_rect: ColorRect = $ColorRect


func _ready() -> void:
	add_to_group("transition_effect")
	if _color_rect:
		_color_rect.color = fade_color
		_color_rect.modulate.a = 0.0
		_color_rect.visible = false


## Tween the ColorRect from transparent to [member fade_color] over [member fade_duration].
func fade_out() -> void:
	if not _color_rect:
		return
	_color_rect.visible = true
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished


## Tween the ColorRect from [member fade_color] back to transparent over [member fade_duration].
func fade_in() -> void:
	if not _color_rect:
		return
	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished
	_color_rect.visible = false

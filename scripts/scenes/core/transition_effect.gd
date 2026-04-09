class_name TransitionEffect
extends Node
## Base class for scene transition effects used by [LevelManager].
## Extend this to create custom transitions (fade, dissolve, wipe, VR shader, etc.).
##
## [b]Setup:[/b] Add your subclass to the [code]"transition_effect"[/code] group.
## LevelManager will find it automatically and call [method fade_out] /
## [method fade_in] during scene changes and teleports.
##
## [b]Creating a custom transition:[/b][br]
## [codeblock]
## class_name MyTransition
## extends TransitionEffect
##
## func fade_out() -> void:
##     # Your "going dark" animation — await it.
##     pass
##
## func fade_in() -> void:
##     # Your "coming back" animation — await it.
##     pass
## [/codeblock]
## See [FadeTransition] for a working example.

## Override this: play the "going dark" animation.
## LevelManager awaits this before changing scenes or teleporting.
func fade_out() -> void:
	pass


## Override this: play the "coming back" animation.
## LevelManager awaits this after the player has been placed.
func fade_in() -> void:
	pass

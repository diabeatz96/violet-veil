extends XROrigin3D

func _ready() -> void:
	var xr_interface := XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.initialize():
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		push_error("OpenXR interface failed to initialize.")

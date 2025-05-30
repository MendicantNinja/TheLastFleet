extends PanelContainer

var MOVE_STYLE_BOX = preload("res://Resources/MoveIndicatorStyleBox.tres")

var nearest_n_resize: int = 16
var min_size_resize: int = 2

func _init():
	var nearest_n: int = floori(nearest_po2(imap_manager.DefaultCellSize) / nearest_n_resize)
	custom_minimum_size.x = imap_manager.DefaultCellSize / 2
	custom_minimum_size.y = imap_manager.DefaultCellSize / 2
	MOVE_STYLE_BOX.border_width_left = nearest_n
	MOVE_STYLE_BOX.border_width_right = nearest_n
	MOVE_STYLE_BOX.border_width_top = nearest_n
	MOVE_STYLE_BOX.border_width_bottom = nearest_n
	add_theme_stylebox_override("panel", MOVE_STYLE_BOX)

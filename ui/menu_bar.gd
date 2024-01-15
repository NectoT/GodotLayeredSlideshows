class_name AppMenuBar extends MenuBar

signal fullscreen_toggled
signal save_config_as_requested(path: String)
signal load_config_requested(path: String)
signal frame_duration_changed(new_frame_duration: float)

@onready var file_menu: PopupMenu = %File
@onready var view_menu: PopupMenu = %View

@onready var save_file_dialog: FileDialog = %SaveFileDialog
@onready var load_file_dialog: FileDialog = %LoadFileDialog
@onready var settings_window: SettingsWindow = %SettingsWindow

func _ready() -> void:
	file_menu.add_item('Save configuration as', 0, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	file_menu.add_item('Open configuration', 1, KEY_MASK_CTRL | KEY_O)
	file_menu.add_item('Common Settings', 2)
	
	file_menu.id_pressed.connect(_on_file_menu_pressed)
	
	view_menu.add_item('Fullscreen', 0, KEY_F)
	view_menu.id_pressed.connect(func(id: int):
		if id == 0:
			fullscreen_toggled.emit()
	)

func _on_settings_window_playback_speed_changed(new_playback_speed: float) -> void:
	frame_duration_changed.emit(new_playback_speed)

func _on_file_menu_pressed(id: int):
	if id == 0:
		save_file_dialog.show()
	elif id == 1:
		load_file_dialog.show()
	elif id == 2:
		settings_window.show()


func _on_config_file_opened_for_loading(path: String):
	load_config_requested.emit(path)


func _on_config_file_opened_for_saving(path: String):
	save_config_as_requested.emit(path)

class_name LayerConfig extends HBoxContainer

signal layer_display_deleted
signal layer_soloed

@export var file_dialog: FileDialog
@export var visibility_button: ToggleButton

var layer: Layer

func _ready() -> void:
	file_dialog.dir_selected.connect(_on_directory_selected)


func _on_opacity_slider_changed(value: float):
	layer.opacity = value


func _on_onion_opacity_slider_changed(value: float):
	layer.onion_skin_opacity_step = 1 - value


func _on_directory_button_pressed():
	file_dialog.visible = true


func _on_directory_selected(dir: String):
	layer.dir_path = dir


func _on_onion_button_toggled():
	layer.onion_skin_enabled = !layer.onion_skin_enabled


func _on_delete_button_pressed():
	layer.get_parent().remove_child(layer)
	layer.queue_free()
	queue_free()
	layer_display_deleted.emit()


func _on_visibility_button_pressed():
	if Input.is_key_pressed(KEY_SHIFT):
		layer_soloed.emit()
	else:
		layer.visible = !layer.visible


func _on_alpha_color_changed(color: Color):
	layer.alpha_color = color


func _on_alpha_checkbox_toggled(toggled_on: bool):
	layer.alpha_enabled = toggled_on


func _process(delta: float) -> void:
	visibility_button.enabled = layer.visible

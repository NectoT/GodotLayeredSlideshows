class_name LayerConfig extends Control

class ModeSettings:
	var onion_skin_mode = Layer.OnionSkinMode.OFF
	var onion_skin_opacity = 0.5
	var opacity = 0.5

signal layer_display_deleted
signal layer_soloed

@export var file_dialog: FileDialog
@export var visibility_button: ToggleButton

@export var opacity_slider: HSlider
@export var onion_skin_selector: OptionButton
@export var onion_skin_opacity_slider: HSlider

@export var directory_name_label: Label

@export var start_frame_input: NumberInput

var layer: Layer:
	set(value):
		layer = value
		if layer.mode == Layer.Mode.DRAW:
			current_settings = draw_settings
		else:
			current_settings = view_settings

var view_settings = ModeSettings.new()
var draw_settings = ModeSettings.new()
var current_settings = view_settings:
	set(value):
		current_settings = value
		if layer != null:
			_apply_settings(layer, value)
			_sync_ui_with_settings(value)

func _ready() -> void:
	file_dialog.dir_selected.connect(_on_directory_selected)
	draw_settings.opacity = 1
	_sync_ui_with_settings(current_settings)


func _on_opacity_slider_changed(value: float):
	current_settings.opacity = value
	layer.opacity = value


func _on_onion_opacity_slider_changed(value: float):
	current_settings.onion_skin_opacity = value
	layer.onion_skin_opacity_step = 1 - value


func _on_directory_button_pressed():
	file_dialog.visible = true


func _on_directory_selected(dir: String):
	layer.dir_path = dir
	directory_name_label.text = dir.split('\\')[-1]


func _on_onion_option_selected(option_id: int):
	current_settings.onion_skin_mode = option_id
	layer.onion_skin_mode = option_id


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


func _on_mode_button_pressed():
	if layer.mode == Layer.Mode.DRAW:
		layer.mode = Layer.Mode.VIEW
		current_settings = view_settings
	else:
		layer.mode = Layer.Mode.DRAW
		current_settings = draw_settings


func _on_frame_step_input_changed(number: int):
	layer.frame_step = number


func _on_frame_start_input_changed(number: int):
	if number == 0:  # Пропускаем ноль
		if layer.start_file_index == 0:
			start_frame_input.number = -1
		else:
			start_frame_input.number = 1
		return
	
	layer.start_file_index = number - 1 if number > 0 else number

func _apply_settings(layer: Layer, settings: ModeSettings):
	layer.opacity = settings.opacity
	layer.onion_skin_mode = settings.onion_skin_mode
	layer.onion_skin_opacity_step = settings.onion_skin_opacity


## Синхронизирует значения в UI-элементах, отвечающих за настройки, связанные
## с режимом слоя
func _sync_ui_with_settings(settings: ModeSettings):
	opacity_slider.value = settings.opacity
	onion_skin_selector.select(settings.onion_skin_mode)
	onion_skin_opacity_slider.value = settings.onion_skin_opacity


func _process(delta: float) -> void:
	visibility_button.enabled = layer.visible

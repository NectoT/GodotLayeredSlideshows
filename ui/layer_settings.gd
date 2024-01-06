class_name LayerConfig extends Control

class ModeSettings:
	var onion_skin_mode = Layer.OnionSkinMode.PREVIOUS
	## Какой силуэт кадра показывать, если действует режим FRAME
	var onion_skin_frame = -1
	## Сколько силуэтов кадров показывать, если действует режим PREVIOUS
	var onion_skin_depth = 0
	var opacity = 0.5
	var is_visible = true

signal layer_display_deleted
signal layer_soloed

@export var file_dialog: FileDialog
@export var visibility_button: ToggleButton

@export var opacity_slider: HSlider
@export var onion_skin_selector: OptionButton
@export var onion_skin_frame_input: NumberInput
@export var onion_skin_depth_input: NumberInput

@export var directory_name_label: Label

@export var start_frame_input: NumberInput

@export var modulation_picker: ColorPickerButton

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

var modulation_enabled = false

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


func _on_onion_skin_frame_input_changed(number: int):
	current_settings.onion_skin_frame = number
	layer.onion_skin_frame = number


func _on_onion_skin_depth_input_changed(number: int):
	current_settings.onion_skin_depth = number
	layer.onion_skin_depth = number


func _on_directory_button_pressed():
	file_dialog.visible = true


func _on_directory_selected(dir: String):
	layer.dir_path = dir
	directory_name_label.text = dir.split('\\')[-1]


func _on_onion_option_selected(option_id: int):
	current_settings.onion_skin_mode = option_id + 1
	layer.onion_skin_mode = option_id + 1
	onion_skin_frame_input.visible = layer.onion_skin_mode == Layer.OnionSkinMode.FRAME
	onion_skin_depth_input.visible = !onion_skin_frame_input.visible


func _on_delete_button_pressed():
	layer.get_parent().remove_child(layer)
	layer.queue_free()
	queue_free()
	layer_display_deleted.emit()


func _on_visibility_button_pressed():
	# TODO: Сделать рабочее солирование слоя
	if false and Input.is_key_pressed(KEY_SHIFT):
		layer_soloed.emit()
	else:
		layer.visible = !layer.visible
		current_settings.is_visible = !current_settings.is_visible


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


func _on_modulation_toggled(enabled: bool):
	modulation_enabled = enabled
	if enabled:
		_set_layer_modulation(modulation_picker.color)
	else:
		_set_layer_modulation(Color.WHITE)


func _on_modulation_color_picked(color: Color):
	if modulation_enabled:
		_set_layer_modulation(color)


func _set_layer_modulation(color: Color):
	layer.modulate.r = color.r
	layer.modulate.g = color.g
	layer.modulate.b = color.b


func _apply_settings(layer: Layer, settings: ModeSettings):
	layer.opacity = settings.opacity
	layer.onion_skin_mode = settings.onion_skin_mode
	layer.onion_skin_frame = settings.onion_skin_frame
	layer.onion_skin_depth = settings.onion_skin_depth
	layer.visible = settings.is_visible


## Синхронизирует значения в UI-элементах, отвечающих за настройки, связанные
## с режимом слоя
func _sync_ui_with_settings(settings: ModeSettings):
	opacity_slider.value = settings.opacity
	onion_skin_selector.select(settings.onion_skin_mode - 1)
	onion_skin_frame_input.number = settings.onion_skin_frame
	onion_skin_depth_input.number = settings.onion_skin_depth
	
	onion_skin_frame_input.visible = layer.onion_skin_mode == Layer.OnionSkinMode.FRAME
	onion_skin_depth_input.visible = !onion_skin_frame_input.visible
	
	visibility_button.enabled = settings.is_visible


func _process(delta: float) -> void:
	visibility_button.enabled = layer.visible

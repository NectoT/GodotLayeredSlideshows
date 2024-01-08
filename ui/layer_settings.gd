class_name LayerConfig extends Control

class ModeSettings:
	var onion_skin_mode = Layer.OnionSkinMode.PREVIOUS
	## Какой силуэт кадра показывать, если действует режим FRAME
	var onion_skin_frame = -1
	## Сколько силуэтов кадров показывать, если действует режим PREVIOUS
	var onion_skin_depth = 0
	var opacity = 0.5
	var is_visible = true
	
	func save_to_config_file(config_file: ConfigFile, layer_section: String, mode_name: String):
		for property_dict in get_property_list():
			if property_dict['usage'] & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
				continue
			
			var name = property_dict['name'] as String
			config_file.set_value(layer_section, mode_name + '_' + name, get(name))
	
	func load_from_config_file(config_file: ConfigFile, layer_section: String, mode_name: String):
		var keys = config_file.get_section_keys(layer_section)
		for key in keys:
			if key.begins_with(mode_name + '_'):
				var property_name = key.trim_prefix(mode_name + '_')
				set(property_name, config_file.get_value(layer_section, key))

signal layer_display_deleted
signal layer_soloed

@export_group('UI Elements')
@export var file_dialog: FileDialog

@export var visibility_button: ToggleButton

@export var mode_button: ToggleButton

@export var opacity_slider: HSlider
@export var onion_skin_selector: OptionButton
@export var onion_skin_frame_input: NumberInput
@export var onion_skin_depth_input: NumberInput

@export var directory_name_label: Label

@export var start_frame_input: NumberInput
@export var frame_step_input: NumberInput

@export var alpha_checkbox: CheckBox
@export var alpha_picker: ColorPickerButton

@export var modulation_checkbox: CheckBox
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
			_sync_ui_with_mode_settings(value)

var modulation_enabled = false

func _ready() -> void:
	file_dialog.dir_selected.connect(_on_directory_selected)
	draw_settings.opacity = 1
	_sync_ui_with_mode_settings(current_settings)


func save_to_config_file(config_file: ConfigFile, layer_section: String):
	draw_settings.save_to_config_file(config_file, layer_section, 'draw_mode')
	view_settings.save_to_config_file(config_file, layer_section, 'view_mode')
	
	config_file.set_value(layer_section, 'dir_path', layer.dir_path)
	config_file.set_value(layer_section, 'mode', layer.mode)
	config_file.set_value(layer_section, 'frame_step', layer.frame_step)
	config_file.set_value(layer_section, 'start_file_index', layer.start_file_index)
	config_file.set_value(layer_section, 'modulation_enabled', modulation_enabled)
	config_file.set_value(layer_section, 'modulation', modulation_picker.color)
	config_file.set_value(layer_section, 'alpha_enabled', layer.alpha_enabled)
	config_file.set_value(layer_section, 'alpha_color', layer.alpha_color)


func load_from_config_file(config_file: ConfigFile, layer_section: String):
	set_layer_mode(config_file.get_value(layer_section, 'mode', 0))
	mode_button.enabled = layer.mode == Layer.Mode.DRAW
	
	draw_settings.load_from_config_file(config_file, layer_section, 'draw_mode')
	view_settings.load_from_config_file(config_file, layer_section, 'view_mode')
	_apply_settings(layer, current_settings)
	
	layer.dir_path = config_file.get_value(layer_section, 'dir_path', "")
	directory_name_label.text = layer.dir_path.split('\\')[-1]
	
	layer.frame_step = config_file.get_value(layer_section, 'frame_step', 1)
	frame_step_input.number = layer.frame_step
	
	layer.start_file_index = config_file.get_value(layer_section, 'start_file_index', 0)
	start_frame_input.number = layer.start_file_index
	if layer.start_file_index >= 0:
		start_frame_input.number += 1
	
	modulation_enabled = config_file.get_value(layer_section, 'modulation_enabled', false)
	modulation_checkbox.button_pressed = modulation_enabled
	
	modulation_picker.color = config_file.get_value(layer_section, 'modulation', Color.BLUE)
	if modulation_enabled:
		_set_layer_modulation(modulation_picker.color)
	else:
		_set_layer_modulation(Color.WHITE)
	
	layer.alpha_enabled = config_file.get_value(layer_section, 'alpha_enabled', false)
	alpha_checkbox.button_pressed = layer.alpha_enabled
	
	layer.alpha_color = config_file.get_value(layer_section, 'alpha_color', Color.BLACK)
	alpha_picker.color = layer.alpha_color
	
	_sync_ui_with_mode_settings(current_settings)


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


func set_layer_mode(mode: Layer.Mode):
	if mode == Layer.Mode.DRAW:
		layer.mode = Layer.Mode.DRAW
		current_settings = draw_settings
	else:
		layer.mode = Layer.Mode.VIEW
		current_settings = view_settings

func _on_frame_step_input_changed(number: int):
	layer.frame_step = number


func _on_frame_start_input_changed(number: int):
	layer.start_file_index = number - 1


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
func _sync_ui_with_mode_settings(settings: ModeSettings):
	opacity_slider.value = settings.opacity
	onion_skin_selector.select(settings.onion_skin_mode - 1)
	onion_skin_frame_input.number = settings.onion_skin_frame
	onion_skin_depth_input.number = settings.onion_skin_depth
	
	onion_skin_frame_input.visible = layer.onion_skin_mode == Layer.OnionSkinMode.FRAME
	onion_skin_depth_input.visible = !onion_skin_frame_input.visible
	
	visibility_button.enabled = settings.is_visible


func _process(delta: float) -> void:
	visibility_button.enabled = layer.visible

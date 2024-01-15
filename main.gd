extends Control

signal current_frame_changed(frame: int)
signal frame_amount_changed(frame_amount: int)

@export var layer: PackedScene
@export var layer_config: PackedScene

@export var display: Control
## Узел, в котором находятся все элементы, связанные с интерфейсом
@export var interface: Control
@export var layers_interface: Control
@export var loading_panel: Control

@export var current_frame_label: Label
@export var total_frames_label: Label

@export var mode_button: ToggleButton

@export var menu_bar: AppMenuBar

const LAYER_SECTION_PREFIX: String = 'Layer'

var frame_duration: float = 1.0 / 12

var stop_frame = 1

var current_frame = 1:
	set(value):
		if value < 1:
			return
		
		current_frame = value
		if not playing_frames:
			stop_frame = current_frame
		
		if current_frame_label != null:
			current_frame_label.text = str(current_frame)
		
		if display == null:
			return
		for layer in display.get_children() as Array[Layer]:
			layer.current_frame = current_frame
var total_frames = 0

var playing_frames = false
var playtime_passed_since_last_frame = 0

var _previous_window_mode: Window.Mode
var fullscreen: bool = false:
	set(value):
		fullscreen = value
		if fullscreen:
			_previous_window_mode = get_window().mode
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = _previous_window_mode

var _is_loading_config = false:
	set(value):
		_is_loading_config = value
		_update_loading_panel()
var _is_loading_images = false:
	set(value):
		_is_loading_images = value
		_update_loading_panel()

var _mode: Layer.Mode = Layer.Mode.VIEW

func _ready() -> void:
	current_frame_label.text = str(current_frame)
	total_frames_label.text = str(total_frames)
	
	# Синхронизируем UI в настройках с реальной скоростью проигрывания
	menu_bar.settings_window.playback_speed = frame_duration


## Скрывает или показывает плашку загрузки в зависимости от того, происходит
## ли загрузка
func _update_loading_panel():
	loading_panel.visible = _is_loading_config or _is_loading_images


func _save_layers_config(path: String):
	var config = ConfigFile.new()
	
	config.set_value('General', 'mode', _mode)
	config.set_value('General', 'frame_duration', frame_duration)
	
	var layer_configs: Array[LayerConfig] = []
	layer_configs.assign(layers_interface.get_children())
	for i in range(len(layer_configs)):
		layer_configs[i].save_to_config_file(config, LAYER_SECTION_PREFIX + str(i))
	
	if not path.ends_with('.ini'):
		path += '.ini'
	config.save(path)


func _load_layers_config(path: String):
	_is_loading_config = true
	await get_tree().process_frame
	
	var config = ConfigFile.new()
	config.load(path)
	
	frame_duration = config.get_value('General', 'frame_duration', 1.0 / 12)
	menu_bar.settings_window.playback_speed = frame_duration
	
	for node in display.get_children():
		node.queue_free()
	for node in layers_interface.get_children():
		node.queue_free()
	
	var sections = config.get_sections()
	#sections.sort()
	sections.reverse()
	
	for section in sections:
		if not section.begins_with(LAYER_SECTION_PREFIX):
			continue
		
		var layer_config_instance = _create_layer()
		layer_config_instance.load_from_config_file(config, section)
	
	_load_mode_from_config(config)
	
	_is_loading_config = false


func _previous_frame():
	if playing_frames:
		_stop_frames()
	current_frame -= 1

func _next_frame():
	if playing_frames:
		_stop_frames()
	current_frame += 1

## Создаёт слой и настройки к нему. Возвращает настройки
func _create_layer() -> LayerConfig:
	var layer_instance = layer.instantiate() as Layer
	layer_instance.current_frame = current_frame
	
	layer_instance.frame_amount_changed.connect(func(_total_frames: int): _update_total_frames())
	layer_instance.images_started_loading.connect(_on_layer_images_loading)
	layer_instance.images_loaded.connect(_on_layer_images_loaded)
	
	var config_instance = layer_config.instantiate() as LayerConfig
	config_instance.layer = layer_instance
	config_instance.layer_display_deleted.connect(_update_total_frames)
	config_instance.layer_soloed.connect(_on_layer_soloed.bind(config_instance))
	
	display.add_child(layer_instance)
	layers_interface.add_child(config_instance)
	layers_interface.move_child(config_instance, 0)
	
	return config_instance


func _on_layer_soloed(soloed_config: LayerConfig):
	# TODO: Сделать рабочее солирование слоя
	pass


func _on_layer_images_loading():
	_is_loading_images = true


func _on_layer_images_loaded():
	_is_loading_images = false


func _update_total_frames():
	total_frames = 0
	for layer in display.get_children() as Array[Layer]:
		if layer.total_frames() > total_frames:
			total_frames = layer.total_frames()
	total_frames_label.text = str(total_frames)


func _play_frames():
	if total_frames < 2:
		return
	
	playtime_passed_since_last_frame = 0
	playing_frames = true
	
	for layer in display.get_children() as Array[Layer]:
		layer.is_playing = true


func _stop_frames():
	current_frame = stop_frame
	playing_frames = false
	
	for layer in display.get_children() as Array[Layer]:
		layer.is_playing = false


func _on_fullscreen_toggled():
	fullscreen = !fullscreen


func _toggle_mode():
	if _mode == Layer.Mode.VIEW:
		_mode = Layer.Mode.DRAW
	else:
		_mode = Layer.Mode.VIEW
	
	for layer_config_instance in layers_interface.get_children() as Array[LayerConfig]:
		layer_config_instance.set_layer_mode(_mode)


func _on_frame_duration_changed(new_framerate: float):
	frame_duration = new_framerate


func _load_mode_from_config(config: ConfigFile):
	_mode = config.get_value('General', 'mode')
	
	for layer_config_instance in layers_interface.get_children() as Array[LayerConfig]:
		layer_config_instance.set_layer_mode(_mode)
	
	mode_button.enabled = _mode == Layer.Mode.DRAW


func _process(delta: float) -> void:
	if Input.is_action_just_pressed('toggle_ui'):
		interface.visible = !interface.visible
		menu_bar.visible = !menu_bar.visible
	
	if Input.is_action_just_pressed('toggle_mode'):
		_toggle_mode()
		mode_button.enabled = !mode_button.enabled
	
	if Input.is_action_just_pressed('next_frame'):
		_next_frame()
	if Input.is_action_just_pressed('previous_frame'):
		_previous_frame()
	
	if playing_frames:
		playtime_passed_since_last_frame += delta
		if playtime_passed_since_last_frame / frame_duration > 1:
			playtime_passed_since_last_frame -= frame_duration
			current_frame += 1
			current_frame %= total_frames

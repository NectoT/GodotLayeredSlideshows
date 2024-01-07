extends Control

signal current_frame_changed(frame: int)
signal frame_amount_changed(frame_amount: int)

@export var layer: PackedScene
@export var layer_config: PackedScene

@export var display: Control
## Узел, в котором находятся все элементы, связанные с интерфейсом
@export var interface: Control
@export var layers_interface: Control

@export var current_frame_label: Label
@export var total_frames_label: Label

var framerate = 12

var stop_frame = 1

var current_frame = 1:
	set(value):
		if value < 1:
			return
		
		current_frame = value
		
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

func _ready() -> void:
	current_frame_label.text = str(current_frame)
	total_frames_label.text = str(total_frames)


func _save_layers_config(path: String):
	var config = ConfigFile.new()
	
	var layer_configs: Array[LayerConfig] = []
	layer_configs.assign(layers_interface.get_children())
	for i in range(len(layer_configs)):
		layer_configs[i].save_to_config_file(config, 'Layer' + str(i))
	
	if not path.ends_with('.ini'):
		path += '.ini'
	config.save(path)


func _load_layers_config(path: String):
	var config = ConfigFile.new()
	config.load(path)
	
	for node in display.get_children():
		node.queue_free()
	for node in layers_interface.get_children():
		node.queue_free()
	
	var sections = config.get_sections()
	#sections.sort()
	sections.reverse()
	
	for section in sections:
		var layer_config_instance = _create_layer()
		layer_config_instance.load_from_config_file(config, section)


func _previous_frame():
	current_frame -= 1

func _next_frame():
	current_frame += 1

## Создаёт слой и настройки к нему. Возвращает настройки
func _create_layer() -> LayerConfig:
	var layer_instance = layer.instantiate() as Layer
	layer_instance.current_frame = current_frame
	
	layer_instance.frame_amount_changed.connect(func(_total_frames: int): _update_total_frames())
	
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


func _update_total_frames():
	total_frames = 0
	for layer in display.get_children() as Array[Layer]:
		if layer.total_frames() > total_frames:
			total_frames = layer.total_frames()
	total_frames_label.text = str(total_frames)


func _play_frames():
	if total_frames < 2:
		return
	
	stop_frame = current_frame
	playtime_passed_since_last_frame = 0
	playing_frames = true
	
	for layer in display.get_children() as Array[Layer]:
		layer.is_playing = true


func _stop_frames():
	current_frame = stop_frame
	playing_frames = false
	
	for layer in display.get_children() as Array[Layer]:
		layer.is_playing = false


func _on_fullscreen_button_pressed():
	fullscreen = !fullscreen


func _process(delta: float) -> void:
	if Input.is_action_just_pressed('toggle_ui'):
		interface.visible = !interface.visible
	
	if Input.is_action_just_pressed('fullscreen_toggle'):
		fullscreen = !fullscreen
	
	if playing_frames:
		playtime_passed_since_last_frame += delta
		var frame_duration = 1.0 / framerate
		if playtime_passed_since_last_frame / frame_duration > 1:
			playtime_passed_since_last_frame -= frame_duration
			current_frame += 1
			current_frame %= total_frames

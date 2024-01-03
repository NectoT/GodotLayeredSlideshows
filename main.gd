extends Control

signal current_frame_changed(frame: int)
signal frame_amount_changed(frame_amount: int)

@export var layer: PackedScene
@export var layer_config: PackedScene

@export var display: Control
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

func _ready() -> void:
	current_frame_label.text = str(current_frame)
	total_frames_label.text = str(total_frames)

func _previous_frame():
	current_frame -= 1

func _next_frame():
	current_frame += 1

func _create_layer():
	var layer_instance = layer.instantiate() as Layer
	layer_instance.current_frame = current_frame
	
	layer_instance.frame_amount_changed.connect(func(_total_frames: int): _update_total_frames())
	
	var config_instance = layer_config.instantiate() as LayerConfig
	config_instance.layer = layer_instance
	config_instance.layer_display_deleted.connect(_update_total_frames)
	config_instance.layer_soloed.connect(_on_layer_soloed.bind(config_instance))
	
	display.add_child(layer_instance)
	layers_interface.add_child(config_instance)


func _on_layer_soloed(layer_config: LayerConfig):
	for layer in display.get_children() as Array[Layer]:
		if layer == layer_config.layer:
			layer.visible = true
		else:
			layer.visible = false


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


func _process(delta: float) -> void:
	if playing_frames:
		playtime_passed_since_last_frame += delta
		var frame_duration = 1.0 / framerate
		if playtime_passed_since_last_frame / frame_duration > 1:
			playtime_passed_since_last_frame -= frame_duration
			current_frame += 1
			current_frame %= total_frames

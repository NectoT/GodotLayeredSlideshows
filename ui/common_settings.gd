class_name SettingsWindow extends Window

signal playback_speed_changed(new_playback_speed)

var playback_speed: float:
	set(value):
		_playback_speed = value
		
		_ms_slider.set_value_no_signal(_playback_speed)
		_set_ms_label_text()
		_fps_input.number = round(1 / _playback_speed)
	get:
		return _playback_speed

var _playback_speed: float = 0

@onready var _ms_label: Label = %MsLabel
@onready var _ms_slider: HSlider = %MsSlider
@onready var _fps_input: NumberInput = %NumberInput

func _ready() -> void:
	close_requested.connect(hide)


func _on_slider_changed(value: float):
	_playback_speed = value
	_set_ms_label_text()
	
	if value == 0:
		_fps_input.number = 0
	else:
		_fps_input.number = round(1 / value)
	
	playback_speed_changed.emit(playback_speed)


func _on_fps_number_changed(number: int):
	_playback_speed = 1.0 / number
	_set_ms_label_text()
	
	_ms_slider.set_value_no_signal(playback_speed)
	
	playback_speed_changed.emit(playback_speed)


func _set_ms_label_text():
	_ms_label.text = '{0} ms per frame'.format([round(playback_speed * 1000)])

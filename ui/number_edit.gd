class_name NumberEdit extends LineEdit

signal number_submitted(new_number: int)

@export var number = 0:
	set(value):
		_number = value
		text = str(value)
		_prev_text = text
	get:
		return _number
	
var _number = 0

var _prev_text = ''

func _ready() -> void:
	_prev_text = str(number)
	text_changed.connect(_on_text_changed)
	
	focus_exited.connect(_on_focus_exited)
	text_submitted.connect(_on_text_submitted)


func _on_text_changed(new_text: String):
	if new_text.is_valid_int():
		_number = text.to_int()
	elif new_text != '':
		var caret_pos = caret_column
		text = _prev_text
		caret_column = caret_pos - 1  # Но почему нужно вычитать единицу?
	
	_prev_text = text


func _on_focus_exited():
	number_submitted.emit(number)


func _on_text_submitted(new_text: String):
	number_submitted.emit(number)

class_name NumberEdit extends LineEdit

signal number_submitted(new_number: int)

@export var number = 0:
	set(value):
		if value != number:
			text = str(value)
		_number = value
		_prev_text = text
	get:
		return _number
	
var _number = 0

var _prev_text = ''

func _ready() -> void:
	_prev_text = str(number)
	text_changed.connect(_on_text_changed)


func _on_text_changed(new_text: String):
	if new_text.is_valid_int():
		_number = text.to_int()
		number_submitted.emit(_number)
	elif new_text != '':
		var caret_pos = caret_column
		text = _prev_text
		caret_column = caret_pos - 1  # Но почему нужно вычитать единицу?
	
	_prev_text = text

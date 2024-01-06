# TODO: tool-скрипт, визуальное изменение сцены в редакторе при изменении экспортных
# переменных; убирание margin при отсутствии текста
class_name NumberInput extends PanelContainer

signal number_changed(number: int)

@export var label_text = "":
	set(value):
		if not is_node_ready():
			await ready
		label_text = value
		_label.text = label_text

@export var number = 0:
	set(value):
		if value < min_number:
			return
		number = value
		number_changed.emit(number)
		
		if not is_node_ready():
			await ready
		_number_label.text = str(number)
@export var min_number = 0

@onready var _label: Label = %Label
@onready var _number_label: Label = %NumberLabel


func _on_up_button_pressed():
	number += 1


func _on_down_button_pressed():
	number -= 1

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
		
		if not is_node_ready():
			await ready
		_number_edit.number = number
@export var min_number = 0

@onready var _label: Label = %Label
@onready var _number_edit: NumberEdit = %NumberEdit


## Устанавливает значение хранящегося числа и передаёт сигнал, если число поменялось
func change_number(new_number: int):
	var prev_number = number
	number = new_number
	if number != prev_number:
		number_changed.emit(number)
		print(number)


func _on_up_button_pressed():
	change_number(number + 1)


func _on_down_button_pressed():
	change_number(number - 1)

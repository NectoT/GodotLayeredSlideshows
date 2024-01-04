class_name ToggleButton extends Button

var highlight_shader = preload("res://ui/highlighter.gdshader")

var enabled = false:
	set(value):
		enabled = value
		if enabled:
			icon = enabled_icon
			text = enabled_text
		else:
			icon = disabled_icon
			text = disabled_text

@export var manual_toggle = false

@export var enabled_icon: Texture2D
@export_multiline var enabled_text: String = ""

var disabled_icon = icon
var disabled_text = text

func _enter_tree() -> void:
	var shader_material = ShaderMaterial.new()
	shader_material.shader = highlight_shader
	self.material = shader_material
	
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	
	pressed.connect(_on_mouse_pressed)

func _on_mouse_pressed():
	if manual_toggle:
		return
	enabled = !enabled


func _on_mouse_entered():
	(self.material as ShaderMaterial).set_shader_parameter('additional_brightness', 0.3)


func _on_mouse_exited():
	(self.material as ShaderMaterial).set_shader_parameter('additional_brightness', 0)

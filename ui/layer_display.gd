class_name Layer extends Control

enum Mode {
	DRAW,
	VIEW
}

signal frame_amount_changed(frame_amount: int)

@export var mainRect: TextureRect
@export var onion_skin_holder: Control

var dir_path: String = "":
	set(value):
		dir_path = value
		if dir_path != "":
			_set_frame()

var current_frame = 1:
	set(value):
		current_frame = value
		if dir_path != "":
			_set_frame()

var onion_skin_enabled = false:
	set(value):
		if value != onion_skin_enabled:
			onion_skin_enabled = value
			_update_onion_skins()

var opacity: float:
	set(value):
		mainRect.modulate.a = value
		_update_onion_skins()
	get:
		return mainRect.modulate.a

var onion_skin_opacity_step = 0.5:
	set(value):
		onion_skin_opacity_step = value
		_update_onion_skins()

var is_playing = false:
	set(value):
		is_playing = value
		_update_onion_skins()

var alpha_color: Color = Color.BLACK:
	set(value):
		_rect_material.set_shader_parameter('alpha_color', value)
	get:
		return _rect_material.get_shader_parameter('alpha_color')
var alpha_enabled = false:
	set(value):
		alpha_enabled = value
		if _rect_material == null:
			return
		
		if alpha_enabled:
			_rect_material.set_shader_parameter('threshold', _alpha_threshold)
		else:
			_rect_material.set_shader_parameter('threshold', -0.1)

var mode: Mode = Mode.VIEW:
	set(value):
		mode = value
		_set_frame()

var _alpha_threshold = 0.1

var _dir_files_amount = 0

var _frames: Array[ImageTexture] = []

@onready var _rect_material = mainRect.material as ShaderMaterial

func _ready() -> void:
	opacity = 0.5


func total_frames() -> int:
	return _dir_files_amount


func _get_sorted_filenames() -> Array[String]:
	if dir_path == "":
		return []
	
	# https://github.com/godotengine/godot/issues/72620 ...
	var filenames: Array[String] = []
	filenames.assign(Array(DirAccess.get_files_at(dir_path)))
	
	filenames.sort_custom(_a_modified_earlier_than_b)
	return filenames as Array[String]


func _load_frames():
	_frames = []
	for name in _get_sorted_filenames():
		var image = Image.load_from_file(dir_path + '/' + name)
		_frames.append(ImageTexture.create_from_image(image))


func _set_frame():
	if _dir_files_amount == 0:
		return
	
	if mode == Mode.VIEW:
		mainRect.texture = _frames[(current_frame - 1) % len(_frames)]
	elif mode == Mode.DRAW:
		if current_frame > _dir_files_amount:
			mainRect.texture = null
		else:
			mainRect.texture = _frames[current_frame - 1]
	
	_update_onion_skins()


func _update_onion_skins():
	if not onion_skin_enabled or is_playing:
		for rect in onion_skin_holder.get_children():
			rect.queue_free()
		return
	
	var sorted_filenames: Array[String] = _get_sorted_filenames()
	var onion_rects = onion_skin_holder.get_children()
	var onion_skin_opacity = opacity - onion_skin_opacity_step
	var skin_amount: int = 0
	while onion_skin_opacity > 0:
		skin_amount += 1
		
		var frame_index = current_frame - 1 - skin_amount
		if frame_index < 0:
			break
		
		var onion_skin: TextureRect
		if len(onion_rects) < skin_amount:
			onion_skin = mainRect.duplicate() as TextureRect
			onion_skin_holder.add_child(onion_skin)
			onion_skin_holder.move_child(onion_skin, 0)
		else:
			onion_skin = onion_rects[skin_amount - 1]
		
		onion_skin.modulate.a = onion_skin_opacity
		onion_skin.texture = _frames[frame_index]
		
		onion_skin_opacity -= onion_skin_opacity_step
	
	for i in range(skin_amount, len(onion_rects)):
		onion_rects[i].queue_free()


func _a_modified_earlier_than_b(a_filename: String, b_filename: String) -> bool:
	var a_file_modified = FileAccess.get_modified_time(dir_path + '/' + a_filename)
	var b_file_modified = FileAccess.get_modified_time(dir_path + '/' + b_filename)
	
	return a_file_modified > b_file_modified


func _process(delta: float) -> void:
	if dir_path == "":
		_dir_files_amount = 0
		return
	
	var new_files_amount = len(DirAccess.get_files_at(dir_path))
	if _dir_files_amount != new_files_amount:
		_load_frames()
		
		_dir_files_amount = new_files_amount
		
		_set_frame()
		
		frame_amount_changed.emit(_dir_files_amount)

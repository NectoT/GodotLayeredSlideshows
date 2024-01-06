class_name Layer extends Control

enum Mode {
	DRAW,
	VIEW
}

enum OnionSkinMode {
	OFF,
	PREVIOUS,
	FIRST  ## Показывается силуэт первого кадра
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

## Откуда идёт отсчёт кадров. Если значение отрицальное, то подразумевается
## отступ от последнего кадра на это число
var start_file_index = 0:
	set(value):
		start_file_index = value
		_set_frame()

var frame_step = 1:
	set(value):
		frame_step = value
		_set_frame()
		frame_amount_changed.emit(total_frames())

var onion_skin_mode: OnionSkinMode = OnionSkinMode.OFF:
	set(value):
		if value != onion_skin_mode:
			onion_skin_mode = value
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

var _images: Array[ImageTexture] = []

@onready var _rect_material = mainRect.material as ShaderMaterial

func _ready() -> void:
	opacity = 0.5


func total_frames() -> int:
	return floor(_dir_files_amount / frame_step)


func _get_sorted_filenames() -> Array[String]:
	if dir_path == "":
		return []
	
	# https://github.com/godotengine/godot/issues/72620 ...
	var filenames: Array[String] = []
	filenames.assign(Array(DirAccess.get_files_at(dir_path)))
	
	filenames.sort_custom(_a_modified_earlier_than_b)
	return filenames as Array[String]


func _load_frames():
	_images = []
	for name in _get_sorted_filenames():
		var image = Image.load_from_file(dir_path + '/' + name)
		_images.append(ImageTexture.create_from_image(image))


func _set_frame():
	if _dir_files_amount == 0:
		return
	
	if mode == Mode.VIEW:
		mainRect.texture = _images[get_file_index(current_frame)]
	elif mode == Mode.DRAW:
		var file_index = get_file_index(current_frame)
		if file_index == -1:
			mainRect.texture = null
		else:
			mainRect.texture = _images[file_index]
	
	_update_onion_skins()


func _update_onion_skins():
	if onion_skin_mode == OnionSkinMode.OFF or is_playing:
		for rect in onion_skin_holder.get_children():
			rect.queue_free()
		return
	
	if onion_skin_mode == OnionSkinMode.FIRST:
		_update_first_frame_onion_skin()
		return
	
	var sorted_filenames: Array[String] = _get_sorted_filenames()
	var onion_rects = onion_skin_holder.get_children()
	var onion_skin_opacity = opacity - onion_skin_opacity_step
	print(onion_skin_opacity)
	var skin_amount: int = 0
	while onion_skin_opacity > 0:
		skin_amount += 1
		
		var frame = current_frame - skin_amount
		if frame < 0:
			break
		
		var onion_skin: TextureRect
		if len(onion_rects) < skin_amount:
			onion_skin = mainRect.duplicate() as TextureRect
			onion_skin_holder.add_child(onion_skin)
			onion_skin_holder.move_child(onion_skin, 0)
		else:
			onion_skin = onion_rects[skin_amount - 1]
		
		onion_skin.modulate.a = onion_skin_opacity
		var file_index = get_file_index(frame)
		if file_index == -1:
			onion_skin.texture = null
		else:
			onion_skin.texture = _images[file_index]
		
		onion_skin_opacity -= onion_skin_opacity_step
	
	for i in range(skin_amount, len(onion_rects)):
		onion_rects[i].queue_free()

## Возвращает индекс файла, соответствующий переданному кадру, или -1, если 
## для кадра нет подходящего файла. Считается на основе шага и режима слоя
func get_file_index(frame: int) -> int:
	if mode == Mode.DRAW:
		var index = start_file_index + (frame - 1) * frame_step
		if index >= _dir_files_amount:
			return -1
		return index % _dir_files_amount
	elif _dir_files_amount == 0:
		return 0
	else:
		print((start_file_index + (frame - 1) * frame_step) % _dir_files_amount)
		return (start_file_index + (frame - 1) * frame_step) % _dir_files_amount


func _update_first_frame_onion_skin():
	if _dir_files_amount == 0:
		return
	
	var onion_rects := onion_skin_holder.get_children()
	for i in range(1, len(onion_rects)):
		onion_rects[i].queue_free()
	
	var onion_rect: TextureRect
	if len(onion_rects) == 0:
		onion_rect = mainRect.duplicate() as TextureRect
		onion_skin_holder.add_child(onion_rect)
	else:
		onion_rect = onion_rects[0] as TextureRect
	
	onion_rect.texture = _images[0]
	onion_rect.modulate.a = opacity - onion_skin_opacity_step


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
		
		frame_amount_changed.emit(total_frames())

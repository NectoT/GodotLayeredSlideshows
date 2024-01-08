class_name Layer extends Control

enum Mode {
	DRAW,
	VIEW
}

enum OnionSkinMode {
	OFF,
	PREVIOUS,  ## Показываются силуэты предыдущих кадров
	FRAME  ## Показывается силуэт выбранного кадра
}

signal frame_amount_changed(frame_amount: int)
signal images_started_loading
signal images_loaded

@export var mainRect: TextureRect
@export var onion_skin_holder: Control

var dir_path: String = ""

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

var onion_skin_mode: OnionSkinMode = OnionSkinMode.PREVIOUS:
	set(value):
		if value != onion_skin_mode:
			onion_skin_mode = value
			_update_onion_skins()

var _onion_skin_opacity_step = 0.2
var _min_onion_skin_opacity = 0.1

var onion_skin_frame: int = -1:
	set(value):
		onion_skin_frame = value
		_update_onion_skins()

var onion_skin_depth: int = 0:
	set(value):
		onion_skin_depth = value
		_update_onion_skins()

var opacity: float:
	set(value):
		mainRect.modulate.a = value
		_update_onion_skins()
	get:
		return mainRect.modulate.a

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

var _filenames: Array[String] = []

var _images: Array[ImageTexture] = []

@onready var _rect_material = mainRect.material as ShaderMaterial

func _ready() -> void:
	opacity = 0.5


func total_frames() -> int:
	if frame_step == 0:
		return 1
	return floor(len(_images) / abs(frame_step))


func _load_images():
	images_started_loading.emit()
	await get_tree().process_frame
	_images = []
	for name in DirAccess.get_files_at(dir_path):
		var image = Image.create(100, 100, false, Image.FORMAT_ASTC_4x4)
		var status_code = image.load(dir_path + '/' + name)
		if status_code == OK:
			_images.append(ImageTexture.create_from_image(image))
		else:
			print('"{0}" could not be loaded as an image'.format([name]))
	images_loaded.emit()


func _set_frame():
	if len(_images) == 0:
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
	
	if onion_skin_mode == OnionSkinMode.FRAME:
		_update_frame_onion_skin()
		return
	
	var onion_rects = onion_skin_holder.get_children()
	var onion_skin_opacity = max(0.1, opacity - _onion_skin_opacity_step)
	var frame = current_frame
	for i in range(onion_skin_depth):
		frame -= 1
		
		var onion_skin: TextureRect
		if len(onion_rects) <= i:
			onion_skin = mainRect.duplicate() as TextureRect
			onion_skin_holder.add_child(onion_skin)
			onion_skin_holder.move_child(onion_skin, 0)
		else:
			onion_skin = onion_rects[i]
		
		onion_skin.modulate.a = onion_skin_opacity
		
		var file_index = get_file_index(frame)
		if file_index == -1:
			onion_skin.texture = null
			return
		else:
			onion_skin.texture = _images[file_index]
		
		onion_skin_opacity -= _onion_skin_opacity_step
		onion_skin_opacity = max(_min_onion_skin_opacity, onion_skin_opacity)
	
	for i in range(onion_skin_depth, len(onion_rects)):
		onion_rects[i].queue_free()

# https://stackoverflow.com/a/60182730
func _python_modulo(n: int, base: int) -> int:
	return n - floor(n/float(base)) * base

## Возвращает индекс файла, соответствующий переданному кадру, или -1, если 
## для кадра нет подходящего файла. Считается на основе шага и режима слоя
func get_file_index(frame: int) -> int:
	var zero_based_frame = frame - 1
	
	if len(_images) == 0:
		return -1

	#print('chose {0} for frame {1}'.format([
		#_python_modulo(
			#start_file_index + zero_based_frame * frame_step, len(_images)
		#),
		#frame
	#]))
	return _python_modulo(
		start_file_index + zero_based_frame * frame_step, len(_images)
	)


func _update_frame_onion_skin():
	if len(_images) == 0:
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
	
	onion_rect.texture = _images[get_file_index(onion_skin_frame)]
	onion_rect.modulate.a = opacity - _onion_skin_opacity_step
	onion_rect.modulate.a = max(_min_onion_skin_opacity, onion_rect.modulate.a)


func _a_modified_earlier_than_b(a_filename: String, b_filename: String) -> bool:
	var a_file_modified = FileAccess.get_modified_time(dir_path + '/' + a_filename)
	var b_file_modified = FileAccess.get_modified_time(dir_path + '/' + b_filename)
	
	return a_file_modified > b_file_modified


func _refresh_loaded_images() -> void:
	if dir_path == "":
		return
	
	var refreshed_filenames: Array[String] = []
	refreshed_filenames.assign(Array(DirAccess.get_files_at(dir_path)))
	if refreshed_filenames.hash() != _filenames.hash():
		var new_total_amount = len(refreshed_filenames) != len(_filenames)
		
		_filenames = refreshed_filenames
		
		await _load_images()
		
		_set_frame()
		
		if new_total_amount:
			frame_amount_changed.emit(total_frames())

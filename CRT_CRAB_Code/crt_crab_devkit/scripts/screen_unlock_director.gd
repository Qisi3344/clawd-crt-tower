class_name ScreenUnlockDirector
extends Node

signal finished(device_index: int)
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/screen_unlocks.json"))
var playing := false
var elapsed := 0.0
var duration := 1.5
var current: MonitorDevice
var audio: GameAudio
var reduced_motion := false
var suspended := false
var frame_cache: Dictionary = {}
var pulses := 0

func frame(index: int, number: int) -> Texture2D:
	var key := Vector2i(index,clampi(number,0,36))
	if frame_cache.has(key): return frame_cache[key]
	var path := "res://assets/pixel/unlock_frames/unlock_%d.png"%index
	if not ResourceLoader.exists(path): return load("res://assets/pixel/standby_%d.png"%index)
	var texture := AtlasTexture.new()
	texture.atlas = load(path)
	texture.region = Rect2((key.y%8)*256,(key.y/8)*192,256,192)
	frame_cache[key] = texture
	return texture

func play(device: MonitorDevice, reduced: bool = false) -> void:
	if playing: return
	current = device
	reduced_motion = reduced
	duration = 0.2 if reduced else 1.5
	elapsed = 0
	pulses = 0
	suspended = false
	playing = true
	current.set_status("UNLOCKING")
	current.set_texture(frame(current.device_index,0))
	await finished

func _process(delta: float) -> void:
	if not playing or suspended: return
	elapsed += delta
	if not reduced_motion:
		current.set_texture(frame(current.device_index,int(minf(elapsed/duration,1)*36)))
		if elapsed>=0.25 and pulses==0:
			pulses=1
			if is_instance_valid(audio): audio.play("select")
		if elapsed>=0.6 and pulses==1:
			pulses=2
			if is_instance_valid(audio): audio.play("select")
	if elapsed>=duration: skip()

func skip() -> void:
	if not playing: return
	playing = false
	current.set_texture(frame(current.device_index,36))
	current.set_status("READY")
	if is_instance_valid(audio): audio.play("unlock")
	finished.emit(current.device_index)

func _input(event: InputEvent) -> void:
	if playing and (event.is_action_pressed("pause") or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		skip()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: suspended = true
	if what==NOTIFICATION_APPLICATION_FOCUS_IN: suspended = false

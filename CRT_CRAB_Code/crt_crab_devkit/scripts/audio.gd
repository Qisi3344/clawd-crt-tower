class_name GameAudio
extends Node

var enabled := true
var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var music_enabled := true
var music_volume := 0.35
var sfx_volume := 0.8
var preferences_enabled := false
var preferences_path := "user://audio.cfg"
var reduced_motion := false
var environment_motion := true
var fullscreen := false
var cursor := 0
var sounds: Dictionary = {}

func _ready() -> void:
	preferences_enabled = not ("--qa" in OS.get_cmdline_user_args() or "--perf" in OS.get_cmdline_user_args())
	var prefs := ConfigFile.new()
	if preferences_enabled and prefs.load(preferences_path)==OK:
		enabled = bool(prefs.get_value("audio","sfx",true))
		music_enabled = bool(prefs.get_value("audio","music",true))
		sfx_volume = clampf(float(prefs.get_value("audio","sfx_volume",0.8)),0,1)
		music_volume = clampf(float(prefs.get_value("audio","volume",0.35)),0,1)
		for key in ["reduced_motion","environment_motion","fullscreen"]: set(key,bool(prefs.get_value("visual",key,get(key))))
	music = AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	music.stream = load("res://assets/audio/no_signal_full.mp3")
	(music.stream as AudioStreamMP3).loop = true
	music.volume_db = -12+linear_to_db(maxf(music_volume,0.0001))
	add_child(music)
	if preferences_enabled:
		music.play()
		music.stream_paused = not music_enabled
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -19+linear_to_db(maxf(sfx_volume,0.0001))
		add_child(voice)
		voices.append(voice)
	var pitches := {"attack":170.0,"hurt":90.0,"hit":330.0,"unlock":740.0,"travel":490.0,"start":600.0,"select":420.0,"purchase":850.0,"error":110.0,"transfer_exit":620.0,"transfer_link":490.0,"transfer_enter":880.0}
	for key in pitches:
		var samples := PackedByteArray()
		var length := 0.17 if key != "unlock" else 0.36
		for i in range(int(22050*length)):
			var t: float = float(i)/22050
			var frequency: float = pitches[key] * (1.0+t*1.8 if key in ["unlock","travel"] else 1.0-t*1.6)
			var value := int(sin(TAU*frequency*t)*pow(1-t/length,2)*18000)
			samples.append(value & 255)
			samples.append((value >> 8) & 255)
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		stream.data = samples
		sounds[key] = stream

func play(kind: String) -> void:
	if not enabled or not sounds.has(kind):
		return
	var voice: AudioStreamPlayer = voices[cursor%voices.size()]
	cursor += 1
	voice.stream = sounds[kind]
	voice.play()

func set_sfx_enabled(value: bool) -> void:
	enabled = value
	_save_audio_preferences()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value,0,1)
	for voice in voices: voice.volume_db = -19+linear_to_db(maxf(sfx_volume,0.0001))
	_save_audio_preferences()

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	music.stream_paused = not value
	_save_audio_preferences()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value,0,1)
	music.volume_db = -12+linear_to_db(maxf(music_volume,0.0001))
	_save_audio_preferences()

func set_visual(key: String, value: bool) -> void:
	if key not in ["reduced_motion","environment_motion","fullscreen"]: return
	set(key,value)
	_save_audio_preferences()

func _save_audio_preferences() -> void:
	if not preferences_enabled: return
	var prefs := ConfigFile.new()
	prefs.set_value("audio","sfx",enabled)
	prefs.set_value("audio","sfx_volume",sfx_volume)
	prefs.set_value("audio","music",music_enabled)
	prefs.set_value("audio","volume",music_volume)
	for key in ["reduced_motion","environment_motion","fullscreen"]: prefs.set_value("visual",key,get(key))
	if prefs.save(preferences_path)!=OK: push_warning("Audio settings could not be saved")

func stop_all() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null

	for voice in voices:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	stop_all()
	sounds.clear()

class_name GameAudio
extends Node

var enabled := true
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var sounds: Dictionary = {}

func _ready() -> void:
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -19
		add_child(voice)
		voices.append(voice)
	var pitches := {"attack":170.0,"hurt":90.0,"hit":330.0,"unlock":740.0,"travel":490.0}
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

func stop_all() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	stop_all()
	sounds.clear()

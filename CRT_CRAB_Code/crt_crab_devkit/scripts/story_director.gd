class_name StoryDirector
extends CanvasLayer

signal finished(kind: String)
signal phase_changed(kind: String, beat: String)
var timelines: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/story_events.json"))
var dialogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/dialogue_zh.json"))
var audio: GameAudio
var desktop: Control
var skip_button: Button
var pause_button: Button
var playing := false
var suspended := false
var clock := 0.0
var kind := "intro"
var event_index := 0
var skin := "classic_orange"
var reduced := false

func _ready() -> void: layer=40
func play(value: String, outfit: String, reduced_motion: bool) -> void:
	if playing: return
	kind=value;skin=outfit;reduced=reduced_motion;clock=0;event_index=0;suspended=false;playing=true
	desktop=load("res://scenes/story/chat_desktop.tscn").instantiate()
	desktop.dialogue=dialogue;desktop.skin=skin;desktop.reduced=reduced;desktop.kind=kind
	add_child(desktop)
	skip_button=Button.new();skip_button.text="跳过剧情  Esc";skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);skip_button.offset_left=-210;skip_button.offset_top=-56;skip_button.offset_right=-24;skip_button.offset_bottom=-16
	desktop.add_child(skip_button);skip_button.pressed.connect(skip);skip_button.grab_focus()
	pause_button=Button.new();pause_button.text="演出已暂停 · 点击或 Enter 继续";pause_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER);pause_button.offset_left=-220;pause_button.offset_right=220;pause_button.offset_top=-28;pause_button.offset_bottom=28;pause_button.hide();desktop.add_child(pause_button)
	pause_button.pressed.connect(func(): suspended=false;pause_button.hide();skip_button.grab_focus())
	_process(0)

func _process(delta: float) -> void:
	if not playing: return
	if suspended: return
	clock+=delta
	var timeline: Dictionary=timelines[kind]
	while event_index<timeline.events.size() and clock>=float(timeline.events[event_index][0]):
		var event: Array=timeline.events[event_index]
		desktop.set_beat(str(event[1]))
		if is_instance_valid(audio): audio.play(str(event[2]))
		phase_changed.emit(kind,str(event[1]));event_index+=1
	desktop.visible=kind!="outro" or clock>=3.8
	desktop.animate(clock)
	if clock>=float(timeline.duration): skip()

func skip() -> void:
	if not playing: return
	playing=false
	if is_instance_valid(desktop): desktop.queue_free()
	finished.emit(kind)

func _input(event: InputEvent) -> void:
	if playing and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled();skip()

func _notification(what: int) -> void:
	if not playing: return
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		suspended=true
		if is_instance_valid(pause_button): pause_button.show()
	if what==NOTIFICATION_APPLICATION_FOCUS_IN:
		if is_instance_valid(pause_button) and suspended: pause_button.grab_focus()

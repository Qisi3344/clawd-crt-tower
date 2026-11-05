class_name ShellDirector
extends Node3D

var camera: Camera3D
var active: MonitorDevice
var overview := false
var reduced_motion := false
var orbit := 0.5
var elevation := 16.0
var busy := false

func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 43
	camera.far = 150
	add_child(camera)
	camera.current = true

func _process(delta: float) -> void:
	if busy or not is_instance_valid(active):
		return
	if overview:
		var target := Vector3(sin(orbit)*29,elevation,cos(orbit)*29)
		camera.position = camera.position.lerp(target,1-exp(-delta*5))
		camera.look_at(Vector3(0,6,0))
	else:
		camera.position = camera.position.lerp(active.focus_position(),1-exp(-delta*8))
		camera.look_at(active.focus_point())

func focus(device: MonitorDevice, instant := false) -> void:
	active = device
	overview = false
	if instant:
		camera.position = active.focus_position()
		camera.look_at(active.focus_point())

func travel(device: MonitorDevice, midpoint: Callable) -> void:
	busy = true
	var old_position := camera.position
	var new_position := device.focus_position()
	var old_focus := active.focus_point()
	var new_focus := device.focus_point()
	var a := atan2(old_position.x,old_position.z)
	var b := a + wrapf(atan2(new_position.x,new_position.z)-a,-PI,PI)
	var duration := 0.35 if reduced_motion else 1.35
	var switched := [false]
	var tween := create_tween()
	tween.tween_method(func(t: float):
		var q := smoothstep(0,1,t)
		var lift := 0.0 if reduced_motion else sin(q*PI)
		var radius := lerpf(Vector2(old_position.x,old_position.z).length(),Vector2(new_position.x,new_position.z).length(),q)+lift*14
		var angle := lerpf(a,b,q)
		camera.position = Vector3(sin(angle)*radius,lerpf(old_position.y,new_position.y,q)+lift*5,cos(angle)*radius)
		camera.look_at(old_focus.lerp(new_focus,q).lerp(Vector3(0,6,0),lift*0.75))
		if q >= 0.5 and not switched[0]:
			switched[0] = true
			midpoint.call()
	,0.0,1.0,duration)
	await tween.finished
	active = device
	busy = false

func toggle_overview() -> void:
	overview = not overview
	if overview:
		orbit = atan2(camera.position.x,camera.position.z)+0.18

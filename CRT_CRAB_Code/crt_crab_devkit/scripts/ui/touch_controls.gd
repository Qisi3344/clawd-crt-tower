class_name TouchControls
extends CanvasLayer

var game: Node
var surface: Control
var guard: Control
var owners: Dictionary={}
var joystick := Vector2.ZERO
var play_visible := false
var array_fingers: Dictionary={}

func _ready() -> void:
	layer=15
	surface=Control.new();surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	surface.set_script(load("res://scripts/ui/touch_surface.gd"));surface.host=self;add_child(surface)
	guard=ColorRect.new();guard.color=Color("17121ff5");guard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(guard)
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);guard.add_child(center)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",24);center.add_child(column)
	var label:=Label.new();label.text="请横屏游玩\n转动设备后自动继续";label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",28);column.add_child(label)
	var button:=Button.new();button.text="切回键鼠操作";button.pressed.connect(func():game.change_profile("keyboard"));column.add_child(button)
	guard.hide()

func centers() -> Dictionary:
	var s:=surface.size
	return {"stick":Vector2(110,s.y-90),"jump":Vector2(s.x-76,s.y-90),"attack":Vector2(s.x-174,s.y-90),"interact":Vector2(s.x-272,s.y-90)}

func refresh() -> void:
	var touch:bool=game.controls.profile=="touch"
	var blocked:bool=touch and get_viewport().get_visible_rect().size.x<get_viewport().get_visible_rect().size.y
	layer=50 if blocked else 15
	guard.visible=blocked
	if game.orientation_blocked!=blocked:
		game.orientation_blocked=blocked;game._control_state()
	var showing:bool=touch and not blocked and game.input_mode==game.InputMode.PLAY_2D and is_instance_valid(game.world) and game.world.enabled
	if play_visible and not showing: release_all()
	play_visible=showing;surface.visible=showing
	if not touch or blocked: release_all()
	surface.queue_redraw()

func release_all() -> void:
	owners.clear();array_fingers.clear();joystick=Vector2.ZERO
	if is_instance_valid(game.input_router): game.input_router.release_all()
	if is_instance_valid(surface): surface.queue_redraw()

func _input(event: InputEvent) -> void:
	if game.controls.profile!="touch" or guard.visible: return
	if game.director.overview:
		if event is InputEventScreenTouch:
			if event.pressed and event.position.y>85 and event.position.x<surface.size.x*.68: array_fingers[event.index]=event.position
			else: array_fingers.erase(event.index)
		if event is InputEventScreenDrag and array_fingers.has(event.index):
			game.director.orbit-=event.relative.x*.007;game.director.elevation=clampf(game.director.elevation+event.relative.y*.025,5,30);get_viewport().set_input_as_handled()
		return
	if not play_visible: return
	var points:=centers()
	if event is InputEventScreenTouch:
		if event.pressed:
			for action in points:
				if event.position.distance_to(points[action])< (70 if action=="stick" else 43):
					if action=="stick" and owners.values().has("stick"): return
					owners[event.index]=action;_update_finger(event.index,event.position);get_viewport().set_input_as_handled();break
		elif owners.has(event.index):
			if owners[event.index]=="stick": joystick=Vector2.ZERO
			owners.erase(event.index);game.input_router.set_source(event.index,{});get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag and owners.has(event.index):
		_update_finger(event.index,event.position);get_viewport().set_input_as_handled()
	surface.queue_redraw()

func _update_finger(id: int, p: Vector2) -> void:
	var action:String=owners[id]
	if action!="stick": game.input_router.set_source(id,{action:1.0});return
	joystick=(p-centers().stick).limit_length(54)/54
	if joystick.length()<.2: joystick=Vector2.ZERO
	game.input_router.set_source(id,{"move_left":maxf(0,-joystick.x),"move_right":maxf(0,joystick.x),"move_up":maxf(0,-joystick.y),"move_down":maxf(0,joystick.y)})

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: release_all()

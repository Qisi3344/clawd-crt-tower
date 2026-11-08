class_name HudIconButton
extends Button

signal activated
var glyph := "array"
var caption := "阵列"
var hint_label: Label
var down_at := -1
var hovering := false
var touch_id := -1

func _ready() -> void:
	set_meta("custom_hud_icon",true)
	custom_minimum_size=Vector2(36,36)
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color("29203388") if state=="normal" else Color("41334dbb")
		box.border_color=Color("e89aaa99") if state in ["normal","disabled"] else Color("8dcabb")
		box.set_border_width_all(1);box.set_corner_radius_all(7)
		box.set_content_margin_all(0)
		add_theme_stylebox_override(state,box)
	hint_label=Label.new();hint_label.text=caption;hint_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hint_label.add_theme_font_size_override("font_size",16);hint_label.add_theme_color_override("font_color",Color("f4e7cf"))
	hint_label.add_theme_color_override("font_shadow_color",Color("17121f"));hint_label.add_theme_constant_override("shadow_offset_y",2)
	hint_label.position=Vector2(-4,40);hint_label.hide();add_child(hint_label)
	mouse_entered.connect(func():hovering=true;if touch_id<0: hint_label.show();queue_redraw())
	mouse_exited.connect(func():hovering=false;hint_label.hide();queue_redraw())
	button_down.connect(func():down_at=Time.get_ticks_msec())
	pressed.connect(func():
		if down_at<0 or Time.get_ticks_msec()-down_at<500: activated.emit()
	)
	button_up.connect(func():if not hovering: hint_label.hide())
	visibility_changed.connect(func():if not is_visible_in_tree(): down_at=-1;hint_label.hide())
	resized.connect(queue_redraw)

func _process(_delta: float) -> void:
	if touch_id>=0 and (down_at<0 or Time.get_ticks_msec()-down_at<500): hint_label.hide()
	if is_pressed() and down_at>=0 and Time.get_ticks_msec()-down_at>=500: hint_label.show()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventScreenTouch: return
	if event.pressed and get_global_rect().has_point(event.position):
		touch_id=event.index;hint_label.hide()
	elif not event.pressed and event.index==touch_id:
		touch_id=-1;hint_label.hide()

func _draw() -> void:
	var p:=size/2
	var color:=Color("8dcabb") if hovering or is_pressed() else Color("e89aaa")
	if disabled: color.a=.35
	match glyph:
		"array":
			for x in range(3):
				for y in range(3): draw_rect(Rect2(p+Vector2(-8+x*6,-8+y*6),Vector2(4,4)),color)
		"map":
			draw_polyline(PackedVector2Array([p+Vector2(-9,-7),p+Vector2(-3,-9),p+Vector2(3,-6),p+Vector2(9,-8),p+Vector2(9,7),p+Vector2(3,9),p+Vector2(-3,6),p+Vector2(-9,8),p+Vector2(-9,-7)]),color,1.5)
			draw_line(p+Vector2(-3,-9),p+Vector2(-3,6),color,1)
			draw_line(p+Vector2(3,-6),p+Vector2(3,9),color,1)
		"pause":
			for x in [-6,2]: draw_rect(Rect2(p+Vector2(x,-8),Vector2(4,16)),color)

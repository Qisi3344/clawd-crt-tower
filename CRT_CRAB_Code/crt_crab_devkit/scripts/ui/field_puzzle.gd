extends CanvasLayer

signal finished(solved: bool)
const FONT = preload("res://assets/fonts/fusion-pixel.otf")
const INK := Color("#242233")
const PAPER := Color("#f4e7cf")
const COLORS := [Color("#8dcabb"), Color("#ffc478"), Color("#e89aaa")]
const PORTS := [[0,6], [4,13], [5,15]]
const INSTRUCTIONS := {
	"wire":"从字母端口拖到同名端口。线路可转弯，不能交叉。",
	"paper":"交换四张碎纸，拼回一份盖有完整圆章的入库回执。",
	"cabinet":"点选数字轮，再按验码。回执记首末位，架号在柜旁。",
	"popup":"核对文件名，点 CACHE.SYS 右侧的关闭键。"
}
const HINTS := {
	"wire":"A 从左上向右绕，B 沿左缘向下，C 从中央通往右下。也可逐格点选。",
	"paper":"红色圆章在四角交会。标题在上，首位在左下，末位在右下。",
	"cabinet":"回执显示 4 和 2，中间一位抄柜旁的架号。",
	"popup":"原进程的扩展名是 .SYS。广告窗把字母换成了近似字符。"
}
var entry: Dictionary
var board := Control.new()
var status := Label.new()
var routes := [[], [], []]
var pieces := [2,0,3,1]
var selected := -1
var paper_offset := Vector2.ZERO
var digits := [0,0,0]
var window_count := 4
var original := 0
var seconds := 18.0
var timer_label: Label
var active_wire := -1
var finger := -1
var cursor := 0
var closing := false

func _ready() -> void:
	layer = 30
	var shade := ColorRect.new()
	shade.color = Color("#151520ed")
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var frame := StyleBoxFlat.new()
	frame.bg_color = INK
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		frame.set_content_margin(side,14)
	panel.add_theme_stylebox_override("panel",frame)
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	column.add_theme_constant_override("separation",12)
	var title := Label.new()
	title.text = entry.label
	title.add_theme_font_size_override("font_size",32)
	column.add_child(title)
	column.add_child(status)
	status.custom_minimum_size.x = 510
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 54
	status.text = INSTRUCTIONS[entry.game]
	if entry.game == "popup":
		timer_label = Label.new()
		column.add_child(timer_label)
		_reset_windows()

	set_process(entry.game == "popup")
	column.add_child(board)
	board.custom_minimum_size = Vector2(510,248)
	board.focus_mode = Control.FOCUS_ALL
	board.draw.connect(_draw_board)
	board.gui_input.connect(_board_input)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	for item in ["提示","重新开始","辅助完成","离开"]:
		var button := Button.new()
		button.text = item
		button.custom_minimum_size.y = 54
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_action.bind(item))
		actions.add_child(button)
	var first := actions.get_child(0) as Button
	var last := actions.get_child(-1) as Button
	board.focus_previous = board.get_path_to(last)
	board.focus_next = board.get_path_to(first)
	last.focus_next = last.get_path_to(board)
	first.focus_previous = first.get_path_to(board)
	board.grab_focus()

func _action(item: String) -> void:
	match item:
		"提示": status.text = HINTS[entry.game]
		"重新开始":
			routes = [[], [], []]
			active_wire = -1
			paper_offset = Vector2.ZERO
			pieces = [2,0,3,1]
			selected = -1
			digits = [0,0,0]
			if entry.game == "popup": _reset_windows()
			status.text = INSTRUCTIONS[entry.game]
			board.queue_redraw()
		"辅助完成": _finish(true)
		"离开": _finish(false)

func _reset_windows() -> void:
	window_count = 4
	original = randi_range(0,window_count-1)
	seconds = 18.0
	timer_label.text = "剩余 18 秒"

func _process(delta: float) -> void:
	if seconds <= 0 or closing or (DisplayServer.get_name()!="headless" and not get_window().has_focus()): return
	seconds = maxf(0,seconds-delta)
	timer_label.text = "剩余 %02d 秒" % ceili(seconds)
	if seconds <= 0:
		status.text = "已超时。可重新开始、辅助完成，或离开终端。"
		board.queue_redraw()

func _finish(solved: bool) -> void:
	if closing: return
	closing = true
	finished.emit(solved)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(false)

func _board_input(event: InputEvent) -> void:
	var grid := _grid()
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT: cursor = maxi(cursor - 1,0)
			KEY_RIGHT: cursor = mini(cursor + 1,grid.x*grid.y-1)
			KEY_UP: cursor = maxi(cursor - grid.x,0)
			KEY_DOWN: cursor = mini(cursor + grid.x,grid.x*grid.y-1)
			KEY_ENTER,KEY_SPACE: _choose(cursor,false)
			_: return
		board.accept_event()
		board.queue_redraw()
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1: finger = event.index
		if finger != event.index: return
		_pointer(event.position, not event.pressed, not event.pressed)
		if not event.pressed: finger = -1
	elif event is InputEventScreenDrag and finger == event.index: _pointer(event.position,true)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(event.position,not event.pressed,not event.pressed)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT: _pointer(event.position,true)
	else: return
	board.accept_event()

func _grid() -> Vector2i:
	match entry.game:
		"paper": return Vector2i(2,2)
		"cabinet": return Vector2i(4,1)
		"popup": return Vector2i(2,3)
	return Vector2i(4,4)

func _pointer(pos: Vector2, dragging: bool, released := false) -> void:
	if not Rect2(Vector2.ZERO,board.size).has_point(pos):
		if released:
			paper_offset = Vector2.ZERO
			board.queue_redraw()
		return
	var grid := _grid()
	var cell := Vector2i(pos / board.size * Vector2(grid))
	cursor = cell.y*grid.x+cell.x
	if entry.game == "popup" and not _close_rect(cursor).has_point(pos): return
	if entry.game == "paper":
		paper_offset = Vector2.ZERO
		if dragging and not released and selected >= 0:
			paper_offset = pos - _tile(selected).get_center()
			board.queue_redraw()
			return
	_choose(cursor,dragging)

func _choose(cell: int, dragging: bool) -> void:
	if closing: return
	match entry.game:
		"wire": _wire(cell,dragging)
		"paper":
			if selected == -1:
				if not dragging: selected = cell
			elif cell != selected:
				var piece: int = pieces[selected]
				pieces[selected] = pieces[cell]
				pieces[cell] = piece
				selected = -1
				if pieces == [0,1,2,3]: _finish(true)
		"cabinet":
			if dragging: return
			if cell < 3: digits[cell] = (digits[cell]+1)%10
			elif "%d%d%d" % digits == str(entry.code): _finish(true)
			else: status.text = "柜锁未开。核对回执首末位，以及柜旁架号。"
		"popup":
			if dragging or seconds<=0 or cell>=window_count: return
			if cell==original: _finish(true)
			elif window_count == 6:
				original = (original + randi_range(1,5)) % 6
				status.text = "窗口已满，进程换了位置。重新核对标题。"
			else:
				window_count += 1
				status.text = "广告又开了一层！核对完整文件名，再点关闭键。"
	board.queue_redraw()

func _wire(cell: int, dragging: bool) -> void:
	if active_wire >= 0:
		var route: Array = routes[active_wire]
		var last: int = route.back()
		if last == cell: return
		var delta := Vector2i(cell%4 - last%4,floori(cell/4.0)-floori(last/4.0)).abs()
		if delta.x + delta.y == 1:
			if route.size()>1 and cell == route[-2]:
				route.pop_back()
				return
			var blocked := false
			for i in PORTS.size():
				if (i!=active_wire and cell in PORTS[i]) or cell in routes[i]: blocked = true
			if not blocked:
				route.append(cell)
				if cell in PORTS[active_wire]:
					active_wire = -1
					var count := 0
					for i in PORTS.size():
						if routes[i].size()>1 and routes[i].back() in PORTS[i]: count += 1
					status.text = "通电 %d / 3" % count
					if count == 3: _finish(true)
				return
			status.text = "这里已有线路或端口。沿原路退一格，或点端口重接。"
	if dragging: return
	for i in PORTS.size():
		if cell in PORTS[i]:
			active_wire = i
			routes[i] = [cell]
			status.text = "正在接 %s 线 · 可拖动或逐格点选" % ["A","B","C"][i]
			return

func _tile(cell: int) -> Rect2:
	var grid := _grid()
	var step := board.size / Vector2(grid)
	return Rect2(Vector2(cell%grid.x,floori(float(cell)/grid.x))*step,step)

func _draw_board() -> void:
	match entry.game:
		"paper": _draw_paper()
		"cabinet": _draw_cabinet()
		"popup": _draw_windows()
		"wire": _draw_wires()
	if board.has_focus(): board.draw_rect(_tile(cursor).grow(-4),PAPER,false,2)

func _draw_wires() -> void:
	for cell in 16:
		var rect := _tile(cell).grow(-3)
		board.draw_rect(rect,INK)
		board.draw_circle(rect.get_center(),3,Color("#68516d"))
	for i in PORTS.size():
		var line := PackedVector2Array()
		for cell in routes[i]: line.append(_tile(cell).get_center())
		if line.size()>1: board.draw_polyline(line,COLORS[i],7)
		for cell in PORTS[i]:
			var p := _tile(cell).get_center()
			board.draw_circle(p,19,COLORS[i])
			board.draw_string(FONT,p+Vector2(-18,9),["A","B","C"][i],HORIZONTAL_ALIGNMENT_CENTER,36,24,INK)

func _draw_paper() -> void:
	var order := [0,1,2,3]
	if selected >= 0:
		order.erase(selected)
		order.append(selected)
	for cell in order:
		var tile := _tile(cell).grow(-5)
		if cell == selected: tile.position += paper_offset
		var piece: int = pieces[cell]
		board.draw_rect(tile,Color("#dfc59b") if cell!=selected else COLORS[0])
		var corner := Vector2(tile.end.x if piece%2==0 else tile.position.x,tile.end.y if piece<2 else tile.position.y)
		var start: float = [PI,1.5*PI,.5*PI,0.0][piece]
		for radius in [42,49]:
			board.draw_arc(corner,radius,start,start+PI/2,20,Color("#aa514d"),3)
		board.draw_string(FONT,tile.position+Vector2(0,tile.size.y*.48),["入库档案","检修回执","首位   4","末位   2"][piece],HORIZONTAL_ALIGNMENT_CENTER,tile.size.x,27,INK)
		var y := tile.position.y+tile.size.y*.65
		board.draw_line(Vector2(tile.position.x+28,y),Vector2(tile.end.x-28,y),Color("#987c64"),2)

func _draw_cabinet() -> void:
	for cell in 4:
		var rect := _tile(cell).grow(-5)
		board.draw_rect(rect,INK)
		board.draw_rect(rect,COLORS[0] if cell==3 else COLORS[1],false,3)
		if cell < 3:
			for offset in [-1,1]:
				var y: float = rect.size.y*.5 + offset*rect.size.y*.29
				board.draw_string(FONT,rect.position+Vector2(0,y+6),str(posmod(digits[cell]+offset,10)),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,19,Color("#a88496"))
				var edge := rect.position+Vector2(10,rect.size.y*.5 + offset*rect.size.y*.15)
				board.draw_line(edge,edge+Vector2(rect.size.x-20,0),Color("#68516d"))
		var label := "验码" if cell==3 else str(digits[cell])
		board.draw_string(FONT,rect.position+Vector2(0,rect.size.y*.5+12),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,32,PAPER)

func _close_rect(cell: int) -> Rect2:
	var rect := _tile(cell).grow(-5)
	return Rect2(rect.end.x-66,rect.position.y,66,rect.size.y)

func _draw_windows() -> void:
	var fake := ["CACHE.ADS","CACHE.LOG","CACHE.SY5","CACHE.TMP","CACHE.BAK","CACHE.SAV"]
	for cell in window_count:
		var rect := _tile(cell).grow(-5)
		board.draw_rect(rect,INK)
		board.draw_rect(rect,Color("#68516d"),false,2)
		var bar := Rect2(rect.position,Vector2(rect.size.x,12))
		board.draw_rect(bar,COLORS[2])
		board.draw_string(FONT,rect.position+Vector2(9,rect.size.y*.65),"CACHE.SYS" if cell==original else fake[cell],HORIZONTAL_ALIGNMENT_LEFT,-1,20,PAPER)
		var close := _close_rect(cell).grow(-5)
		board.draw_rect(close,Color("#41334d"))
		var c := close.get_center()
		board.draw_line(c-Vector2(9,9),c+Vector2(9,9),PAPER,3)
		board.draw_line(c+Vector2(-9,9),c+Vector2(9,-9),PAPER,3)

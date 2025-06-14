extends Control
class_name SlotNode

var item:ItemResource = null:
	set(value):
		item = value
		if value == null:
			$Panel/Amount.text = ""
			$Panel/Icon.texture = null
		else:
			$Panel/Icon.texture = value.icon
			amount = value.amount
			# Hide amount if not stackable
			$Panel/Amount.text = "" if not value.is_stackable else str(value.amount)

var amount:int = 0:
	set(value):
		amount = value
		# Only show amount if stackable and > 0
		if item and item.is_stackable and value > 0:
			$Panel/Amount.text = str(value)
		else:
			$Panel/Amount.text = ""
		if value <= 0:
			item = null

static var split_mode = false
static var split_source = null
static var split_amount = 0
static var split_item = null
static var split_preview = null
static var ctrl_held = false

var is_dragged = false
var drag_preview = null
var drag_item = null
var drag_amount = 0
var drag_start = Vector2.ZERO

func _process(delta):
	if split_preview:
		split_preview.global_position = get_viewport().get_mouse_position() - split_preview.size/2
	if drag_preview:
		drag_preview.global_position = get_viewport().get_mouse_position() - drag_preview.size/2

func _unhandled_key_input(e):
	if e.keycode == KEY_CTRL:
		ctrl_held = e.pressed

func _gui_input(e):
	# Only allow split if item is stackable
	if not split_mode and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and ctrl_held and item and item.is_stackable and amount > 1:
		split_mode = true
		split_source = self
		split_amount = 1
		split_item = item.duplicate()
		split_item.amount = split_amount
		_show_preview(split_item, split_amount, true)
		return
	if split_mode and ctrl_held and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and self == split_source and split_amount < split_source.amount:
		split_amount += 1
		_show_preview(split_item, split_amount, true)
		return
	if split_mode and not ctrl_held and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and self != split_source:
		if item and item.title == split_item.title:
			amount += split_amount
		else:
			item = split_item.duplicate()
			amount = split_amount
		split_source.amount -= split_amount
		_clear_split()
		return
	if not split_mode:
		if e is InputEventMouseButton:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed and item:
				drag_start = e.position
				is_dragged = false
			elif e.button_index == MOUSE_BUTTON_LEFT and not e.pressed and is_dragged:
				_try_drop()
				_end_drag()
			elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and amount > 0:
				amount -= 1
				if split_mode and self == split_source and split_amount > amount:
					split_amount = max(1, amount)
					_show_preview(split_item, split_amount, true)
		elif e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and item and not is_dragged and (e.position-drag_start).length() > 10:
			is_dragged = true
			drag_item = item
			drag_amount = amount
			item = null
			amount = 0
			_show_preview(drag_item, drag_amount, false)

func _try_drop():
	var m = get_viewport().get_mouse_position()
	for s in get_parent().get_children():
		if s is SlotNode and s.get_global_rect().has_point(m):
			if s == self:
				item = drag_item
				amount = drag_amount
			else:
				s._drop_item(self, drag_item, drag_amount)
			return
	item = drag_item
	amount = drag_amount

func _drop_item(src, it, amt):
	if item and it and item.title == it.title and item.is_stackable and it.is_stackable:
		var max_stack = item.max_stack_amount
		var combined = amount + amt
		if combined > max_stack:
			var excess = combined - max_stack
			amount = max_stack
			src.item = it
			src.amount = excess
			#print(excess)
		else:
			amount = combined
			src.item = null
			src.amount = 0
	else:
		var t = item
		var n = amount
		item = it
		amount = amt
		src.item = t
		src.amount = n



func _show_preview(it, amt, is_split):
	_clear_preview()
	var p = preload("res://Inventory/Preview/preview.tscn").instantiate()
	p.item = it
	p.amount = amt
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.modulate = Color(1,1,1,0.7)
	get_tree().root.add_child(p)
	p.global_position = get_viewport().get_mouse_position() - p.size/2
	if is_split: split_preview = p
	else: drag_preview = p

func _clear_preview():
	if drag_preview: drag_preview.queue_free(); drag_preview = null
	if split_preview: split_preview.queue_free(); split_preview = null

func _clear_split():
	_clear_preview()
	split_mode = false
	split_source = null
	split_amount = 0
	split_item = null

func _end_drag():
	is_dragged = false
	_clear_preview()
	drag_item = null
	drag_amount = 0

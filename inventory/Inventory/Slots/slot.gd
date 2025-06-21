extends Control
class_name SlotNode

signal item_dropped(source_slot:SlotNode, target_slot:SlotNode, item:ItemResource, amount:int)
signal item_clicked_on(source_slot:SlotNode, item:ItemResource, amount:int)

# General parameters to adjust to the needs
var is_static_tooltip:bool = true
var tooltip_delay_time:float = 0.1

# Static drag state (shared for all SlotNodes)
static var drag_active: bool = false
static var drag_item: ItemResource = null
static var drag_amount: int = 0
static var drag_source: SlotNode = null
static var drag_preview: Control = null

var drag_start: Vector2 = Vector2.ZERO
var is_dragged: bool = false
# Static split state
static var split_mode: bool = false
static var split_source: SlotNode = null
static var split_amount: int = 0
static var split_item: ItemResource = null
static var split_preview: Control = null
static var ctrl_held: bool = false

# Tooltip
const TOOLTIP = preload("res://Inventory/Tooltip/tooltip.tscn")
var tooltip_instance: Control = null
var tooltip_timer: Timer = null
var tooltip_pending: bool = false
var tooltip_offset:Vector2 = Vector2(10.,10.)

# Instance variables
var item: ItemResource = null:
	set(value):
		item = value
		if value == null:
			$Panel/Amount.text = ""
			$Panel/Icon.texture = null
		else:
			$Panel/Icon.texture = value.icon
			amount = value.amount
			$Panel/Amount.text = "" if not value.is_stackable else str(value.amount)

var amount: int = 0:
	set(value):
		amount = value
		if item and item.is_stackable and value > 0:
			$Panel/Amount.text = str(value)
		else:
			$Panel/Amount.text = ""
		if value <= 0:
			item = null

func _ready():
	# Add a timer for tooltip delay
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = tooltip_delay_time
	tooltip_timer.one_shot = true
	tooltip_timer.connect("timeout", Callable(self, "_on_tooltip_timer_timeout"))
	add_child(tooltip_timer)

	var l:Label = Label.new()
	l.add_theme_font_size_override("font_size",8)
	l.text = str(self.name)
	add_child(l)

func _process(_delta):
	if split_preview:
		split_preview.global_position = get_viewport().get_mouse_position() - split_preview.size / 2
	if drag_preview:
		drag_preview.global_position = get_viewport().get_mouse_position() - drag_preview.size / 2

	# Move tooltip with mouse if active
	if tooltip_instance and not is_static_tooltip:
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip_instance.global_position = mouse_pos + tooltip_offset

func _unhandled_key_input(e):
	if e.keycode == KEY_CTRL:
		ctrl_held = e.pressed

func _unhandled_input(event):
	if split_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if not _check_if_above_slot():
				emit_signal("item_dropped", split_source, null, split_item, split_amount)
				_clear_split()
	# Cancel the split no right mouse click
	if split_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
				_clear_split()



func _gui_input(e):
	# Handle split drop outside any slot (left mouse release)
	if split_mode and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		# Check if mouse is not over any slot
		if not _check_if_above_slot():
			emit_signal("item_dropped", self, null, split_item, split_amount)
			_clear_split()
			return



	# Handle split logic
	if e is InputEventMouseButton and _try_split_global(e):
		return

	# Dragging
	if not split_mode:
		if e is InputEventMouseButton:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed and item:
				# EMIT THE SIGNAL WHEN CLICKED
				emit_signal("item_clicked_on", self, item, amount)
				drag_start = e.position
				is_dragged = false
			elif e.button_index == MOUSE_BUTTON_LEFT and not e.pressed and is_dragged:
				_try_drop_global()
				_end_drag()
			elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and amount > 0:
				amount -= 1
				if split_mode and self == split_source and split_amount > amount:
					split_amount = max(1, amount)
					_show_preview(split_item, split_amount, true)
		elif e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and item and not is_dragged and (e.position - drag_start).length() > 10:
			is_dragged = true
			_start_drag()

func _try_split_global(e: InputEventMouseButton) -> bool:
	# Early exit if not a left click
	if e.button_index != MOUSE_BUTTON_LEFT or not e.pressed:
		return false

	# Not in split mode: check if we should enter it
	if not split_mode and ctrl_held and item and item.is_stackable and amount > 1:
		split_mode = true
		split_source = self
		split_amount = 1
		split_item = item.duplicate()
		split_item.amount = split_amount
		_show_preview(split_item, split_amount, true)
		return true

	# In split mode: check if it's possible to increase split amount
	if split_mode and ctrl_held and self == split_source and split_amount < split_source.amount:
		split_amount += 1
		_show_preview(split_item, split_amount, true)
		return true

	# In split mode: check if it's possible to finalize the split (drop onto another slot)
	if split_mode and not ctrl_held and self != split_source:
		if item and item.title == split_item.title: # Slot of the same type
			amount += split_amount
		elif item == null: # Slot is empty
			item = split_item.duplicate()
			amount = split_amount
		else :  # Don't do anything
			return false
		emit_signal("item_dropped", split_source, self, split_item, split_amount)
		split_source.amount -= split_amount
		_clear_split()
		return true

	return false

func _start_drag():
	drag_active = true
	drag_item = item
	drag_amount = amount
	drag_source = self
	item = null
	amount = 0
	_show_preview(drag_item, drag_amount, false)

func _try_drop_global():
	var mouse_pos = get_viewport().get_mouse_position()
	var found_slot: SlotNode = null
	for slot in _get_all_slots():
		if slot.get_global_rect().has_point(mouse_pos):
			found_slot = slot
			break
	if found_slot:
		if found_slot == self:
			# Dropping on self, just restore
			self.item = drag_item
			self.amount = drag_amount
		else:
			found_slot._drop_item(self, drag_item, drag_amount)
			found_slot.emit_signal("item_dropped", self, found_slot, drag_item, drag_amount)
	else:
		# Optionally: implement dropping outside to "destroy" or "drop" item
		self.item = drag_item
		self.amount = drag_amount
		self.emit_signal("item_dropped", self, null, drag_item, drag_amount)

func _check_if_above_slot():
	var mouse_pos = get_viewport().get_mouse_position()
	var found_slot: SlotNode = null
	for slot in _get_all_slots():
		if slot.get_global_rect().has_point(mouse_pos):
			found_slot = slot
			break
	return found_slot != null

func _drop_item(src: SlotNode, item: ItemResource, amt: int):
	if item and item and item.title == item.title and item.is_stackable and item.is_stackable:
		var max_stack = item.max_stack_amount
		var combined = amount + amt
		if combined > max_stack:
			var excess = combined - max_stack
			amount = max_stack
			src.item = item
			src.amount = excess
		else:
			amount = combined
			src.item = null
			src.amount = 0
	else:
		var t = item
		var n = amount
		item = item
		amount = amt
		src.item = t
		src.amount = n

func _show_preview(item: ItemResource, amt: int, is_split: bool):
	_clear_preview()
	var p = preload("res://Inventory/Preview/preview.tscn").instantiate()
	p.item = item
	p.amount = amt
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.modulate = Color(1, 1, 1, 0.7)
	get_tree().root.add_child(p)
	p.global_position = get_viewport().get_mouse_position() - p.size / 2
	if is_split:
		split_preview = p
	else:
		drag_preview = p

func _clear_preview():
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	if split_preview:
		split_preview.queue_free()
		split_preview = null

func _clear_split():
	_clear_preview()
	split_mode = false
	split_source = null
	split_amount = 0
	split_item = null

func _end_drag():
	drag_active = false
	is_dragged = false
	_clear_preview()
	drag_item = null
	drag_amount = 0
	drag_source = null

func _get_all_slots() -> Array:
	var slots = []
	var root = get_tree().root
	_find_slots_recursive(root, slots)
	return slots

static func _find_slots_recursive(node: Node, slots: Array) -> void:
	if node is SlotNode:
		slots.append(node)
	for child in node.get_children():
		_find_slots_recursive(child, slots)

# Tooltip

func _on_mouse_entered() -> void:
	if item and not tooltip_instance and not tooltip_pending:
		tooltip_pending = true
		tooltip_timer.start()

func _on_mouse_exited() -> void:
	_hide_tooltip()

func _on_tooltip_timer_timeout():
	if tooltip_pending and item:
		_show_tooltip()
	tooltip_pending = false

func _show_tooltip():
	_hide_tooltip()
	tooltip_instance = TOOLTIP.instantiate()
	tooltip_instance._update_tooltip(item.title, item.description, item.stats)
	# Add to root so item overlays everything
	get_tree().root.add_child(tooltip_instance)
	var mouse_pos = get_viewport().get_mouse_position()
	tooltip_instance.global_position = mouse_pos + tooltip_offset

func _hide_tooltip():
	tooltip_pending = false
	if tooltip_timer and tooltip_timer.is_stopped() == false:
		tooltip_timer.stop()
	if tooltip_instance:
		tooltip_instance.queue_free()
		tooltip_instance = null

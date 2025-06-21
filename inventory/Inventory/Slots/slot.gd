extends Control
class_name SlotNode

signal item_dropped(source_slot:SlotNode, target_slot:SlotNode, stack:StackItemResourceClass, amount:int)
signal item_clicked_on(source_slot:SlotNode, stack:StackItemResourceClass, amount:int)

var is_static_tooltip:bool = true
var tooltip_delay_time:float = 0.1

static var drag_active: bool = false
static var drag_stack: StackItemResourceClass = null
static var drag_amount: int = 0
static var drag_source: SlotNode = null
static var drag_preview: Control = null

static var split_mode: bool = false
static var split_source: SlotNode = null
static var split_amount: int = 0
static var split_stack: StackItemResourceClass = null
static var split_preview: Control = null
static var ctrl_held: bool = false

const TOOLTIP = preload("res://Inventory/Tooltip/tooltip.tscn")
var tooltip_instance: Control = null
var tooltip_timer: Timer = null
var tooltip_pending: bool = false
var tooltip_offset := Vector2(10, 10)

var drag_start := Vector2.ZERO
var is_dragged := false

var stack: StackItemResourceClass = StackItemResourceClass.new():
	set(value):
		stack = value
		_update_visuals()

func _update_visuals():
	if stack == null or stack.is_empty():
		$Panel/Amount.text = ""
		$Panel/Icon.texture = null
	else:
		var first_item = stack.get_first_item()
		$Panel/Icon.texture = first_item.icon if first_item else null
		$Panel/Amount.text = str(stack.get_amount()) if first_item and first_item.is_stackable else ""

func _ready():
	_init_tooltip_timer()

func _process(_delta):
	_update_previews()
	_update_tooltip_position()

func _unhandled_key_input(e):
	if e.keycode == KEY_CTRL:
		ctrl_held = e.pressed

func _unhandled_input(event):
	if split_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not _is_mouse_over_slot():
			_emit_and_clear_split(null)
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_clear_split()

func _gui_input(e):
	if split_mode and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		if not _is_mouse_over_slot():
			_emit_and_clear_split(null)
		return
	if e is InputEventMouseButton and _handle_split_logic(e):
		return
	if not split_mode:
		_handle_drag_and_click(e)

func _handle_drag_and_click(e):
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed and stack and not stack.is_empty():
				emit_signal("item_clicked_on", self, stack, stack.get_amount())
				drag_start = e.position
				is_dragged = false
			elif not e.pressed and is_dragged:
				_try_drop_global()
				_end_drag()
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and stack and stack.get_amount() > 0:
			stack.remove_amount(1)
			_update_visuals()
	elif e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and stack and not is_dragged and (e.position - drag_start).length() > 10:
		is_dragged = true
		_start_drag()

func _handle_split_logic(e: InputEventMouseButton) -> bool:
	if e.button_index != MOUSE_BUTTON_LEFT or not e.pressed:
		return false
	if not split_mode and ctrl_held and stack and not stack.is_empty():
		_enter_split_mode()
		return true
	if split_mode and ctrl_held and self == split_source and split_amount < split_source.stack.get_amount():
		split_amount += 1
		split_stack.items.clear()
		for i in range(split_amount):
			if i < stack.items.size():
				split_stack.items.append(stack.items[i].duplicate())
		_show_preview(split_stack, split_amount, true)
		return true

	if split_mode and not ctrl_held and self != split_source:
		_finalize_split()
		return true
	return false

func _enter_split_mode():
	split_mode = true
	split_source = self
	split_amount = 1
	split_stack = StackItemResourceClass.new()
	# Add the first split_amount items to the split stack
	for i in range(split_amount):
		if i < stack.items.size():
			split_stack.items.append(stack.items[i].duplicate())
	_show_preview(split_stack, split_amount, true)


func _finalize_split():
	var my_item = stack.get_first_item()
	var split_item = split_stack.get_first_item()
	if my_item and split_item and my_item.title == split_item.title:
		for i in split_stack.items:
			stack.items.append(i.duplicate())
		_update_visuals()
	elif not stack or stack.is_empty():
		stack = split_stack
		_update_visuals()
	else:
		return
	emit_signal("item_dropped", split_source, self, split_stack, split_amount)
	# Remove the split items from the source stack
	split_source.stack.items = split_source.stack.items.slice(split_amount, split_source.stack.items.size() )
	split_source._update_visuals()
	_clear_split()



func _emit_and_clear_split(target):
	emit_signal("item_dropped", split_source, target, split_stack, split_amount)
	_clear_split()

func _clear_split():
	_clear_preview()
	split_mode = false
	split_source = null
	split_amount = 0
	split_stack = null

func _start_drag():
	drag_active = true
	drag_stack = stack
	drag_amount = stack.get_amount()
	drag_source = self
	stack = StackItemResourceClass.new()
	_update_visuals()
	_show_preview(drag_stack, drag_amount, false)

func _try_drop_global():
	var slot = _find_slot_under_mouse()
	if slot:
		if slot == self:
			self.stack = drag_stack
			self._update_visuals()
		else:
			slot._drop_stack(self, drag_stack, drag_amount)
			slot.emit_signal("item_dropped", self, slot, drag_stack, drag_amount)
	else:
		self.stack = drag_stack
		self._update_visuals()
		self.emit_signal("item_dropped", self, null, drag_stack, drag_amount)

func _drop_stack(src: SlotNode, dropped_stack: StackItemResourceClass, dropped_amt: int):
	if stack and not stack.is_empty() and dropped_stack and not dropped_stack.is_empty() and stack.get_first_item().title == dropped_stack.get_first_item().title and stack.get_first_item().is_stackable and dropped_stack.get_first_item().is_stackable:
		var max_stack = stack.get_first_item().max_stack_amount
		var can_stack = max_stack - stack.get_amount()
		var to_add = min(can_stack, dropped_stack.get_amount())
		for i in range(to_add):
			stack.items.append(dropped_stack.items.pop_front())
		src.stack = dropped_stack
		src._update_visuals()
		_update_visuals()
	else:
		var tmp_stack = stack
		stack = dropped_stack
		src.stack = tmp_stack
		_update_visuals()
		src._update_visuals()

func _end_drag():
	drag_active = false
	is_dragged = false
	_clear_preview()
	drag_stack = null
	drag_amount = 0
	drag_source = null

func _show_preview(stack: StackItemResourceClass, amt: int, is_split: bool):
	_clear_preview()
	var p = preload("res://Inventory/Preview/preview.tscn").instantiate()
	p.item = stack.get_first_item()
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

func _update_previews():
	if split_preview:
		split_preview.global_position = get_viewport().get_mouse_position() - split_preview.size / 2
	if drag_preview:
		drag_preview.global_position = get_viewport().get_mouse_position() - drag_preview.size / 2

func _get_all_slots() -> Array:
	var slots = []
	_find_slots_recursive(get_tree().root, slots)
	return slots

static func _find_slots_recursive(node: Node, slots: Array) -> void:
	if node is SlotNode:
		slots.append(node)
	for child in node.get_children():
		_find_slots_recursive(child, slots)

func _find_slot_under_mouse() -> SlotNode:
	var mouse_pos = get_viewport().get_mouse_position()
	for slot in _get_all_slots():
		if slot.get_global_rect().has_point(mouse_pos):
			return slot
	return null

func _is_mouse_over_slot() -> bool:
	return _find_slot_under_mouse() != null

func _init_tooltip_timer():
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = tooltip_delay_time
	tooltip_timer.one_shot = true
	tooltip_timer.connect("timeout", Callable(self, "_on_tooltip_timer_timeout"))
	add_child(tooltip_timer)

func _update_tooltip_position():
	if tooltip_instance and not is_static_tooltip:
		tooltip_instance.global_position = get_viewport().get_mouse_position() + tooltip_offset

func _on_mouse_entered():
	if stack and not stack.is_empty() and not tooltip_instance and not tooltip_pending:
		tooltip_pending = true
		tooltip_timer.start()

func _on_mouse_exited():
	_hide_tooltip()

func _on_tooltip_timer_timeout():
	if tooltip_pending and stack and not stack.is_empty():
		_show_tooltip()
		tooltip_pending = false

func _show_tooltip():
	var stats:Array = get_stats_ranges(stack)
	_hide_tooltip()
	var first_item = stack.get_first_item()
	tooltip_instance = TOOLTIP.instantiate()
	tooltip_instance._update_tooltip(first_item.title, first_item.description, stats)
	get_tree().root.add_child(tooltip_instance)
	tooltip_instance.global_position = get_viewport().get_mouse_position() + tooltip_offset

func _hide_tooltip():
	tooltip_pending = false
	if tooltip_timer and not tooltip_timer.is_stopped():
		tooltip_timer.stop()
	if tooltip_instance:
		tooltip_instance.queue_free()
		tooltip_instance = null

func get_parent_inventory(inventories)->InventoryClass:
	for i:InventoryClass in inventories:
		for s:SlotNode in i.get_slots():
			if s == self:
				return i
	return null

func get_stats_ranges(s: StackItemResourceClass) -> Array:
	var stat_values := {} # Dictionary: key = StatsEnum, value = Array of stat values

	# Collect all stat values for each stat enum across all items
	for item in s.items:
		for stat in item.stats:
			if not stat_values.has(stat.stat):
				stat_values[stat.stat] = []
			stat_values[stat.stat].append(stat.value)

	var result := []

	# For each stat, determine if all values are the same or get min/max range
	for stat_enum in stat_values.keys():
		var values = stat_values[stat_enum]
		if values.size() == 0:
			continue

		var all_same = true
		var first_value = values[0]
		for v in values:
			if v != first_value:
				all_same = false
				break

		if all_same:
			# All values identical, store single value
			result.append([stat_enum, first_value])
		else:
			# Values differ, store [min, max]
			var min_val = values[0]
			var max_val = values[0]
			for v in values:
				if v < min_val:
					min_val = v
				if v > max_val:
					max_val = v
			result.append([stat_enum, [min_val, max_val]])

	return result

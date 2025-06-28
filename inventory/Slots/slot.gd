extends Control
class_name Slot

signal _on_clicked	(slot:Slot)
signal _on_drag_started	(from_slot:Slot)
signal _on_drag_ended	(from_slot:Slot)
signal _on_double_clicked (slot:Slot)

var slot_content:SlotContent = SlotContent.new()

# Drag
var is_dragged = false
var drag_start_position = Vector2.ZERO
var drag_threshold:float = 10.

# Tooltip
const tooltip = preload("uid://ca1s6tqtfpy34")
var tooltip_instance: Control = null
var tooltip_timer: Timer = null
var tooltip_offset := Vector2(10, 10)
var is_static_tooltip:bool = true
var tooltip_delay_time:float = 0.2

# Double click detection
var click_timer: Timer = null
var click_count: int = 0
const DOUBLE_CLICK_DELAY: float = 0.3

func _ready() -> void:
	slot_content.connect("slot_content_changed",_on_slot_content_changed)
	#_debug_visuals()
	_init_tooltip_timer()
	_init_click_timer()

func _on_slot_content_changed(slot_content_res:SlotContent):
	_update_visuals()

func _process(delta: float) -> void:
	_update_tooltip_position()

func _gui_input(event: InputEvent) -> void:
	_handle_drag(event)
	_handle_click(event)

func _handle_drag(event:InputEvent):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_dragged and (event.global_position - drag_start_position).length() > drag_threshold:
		emit_signal("_on_drag_started",self)
		is_dragged = true

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and is_dragged:
		emit_signal("_on_drag_ended",self)
		is_dragged = false
func _handle_click(event:InputEvent):

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		drag_start_position = event.global_position
		emit_signal("_on_clicked",self)
	_handle_double_click(event)
func _update_visuals():
	$Panel/MarginContainer/Icon.texture = slot_content.get_first_item().icon if not slot_content.is_empty() else null
	$Panel/MarginContainer/Amount.text = str(slot_content.get_amount()) if slot_content.get_amount() > 1 else ""
	return
func _debug_visuals():
	var l:Label = Label.new()
	l.text=self.name
	l.add_theme_font_size_override("font_size",8)
	add_child(l)

# EXPOSED FUNCTIONS ONE LEVEL ABOVE FOR USEABILITY

func add_item(item:Item)->Item:
	return slot_content.add_item(item)

func set_content(new_content:Array[Item]):
	slot_content.set_content(new_content)

func merge_content(content_to_merge:Array[Item]):
	slot_content.merge_content(content_to_merge)

# Tooltip
func _on_mouse_entered() -> void:
	modulate = Color(0.8, 0.8, 0.8, 1.0)
	if not slot_content.is_empty() and not tooltip_instance:
		tooltip_timer.start()

func _on_mouse_exited() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	_hide_tooltip()

func _on_tooltip_timer_timeout():
	if slot_content and not slot_content.is_empty():
		_show_tooltip()

func _show_tooltip():
	#var stats:Array = get_stats_ranges(stack)
	_hide_tooltip()
	var first_item = slot_content.get_first_item()
	tooltip_instance = tooltip.instantiate()
	tooltip_instance._update(first_item.title, first_item.description, slot_content.get_stats_range())
	get_tree().root.add_child(tooltip_instance)
	tooltip_instance.global_position = get_viewport().get_mouse_position() + tooltip_offset

func _hide_tooltip():
	if tooltip_timer and not tooltip_timer.is_stopped():
		tooltip_timer.stop()
	if tooltip_instance:
		tooltip_instance.queue_free()
		tooltip_instance = null

func _update_tooltip_position():
	if tooltip_instance and not is_static_tooltip:
		tooltip_instance.global_position = get_viewport().get_mouse_position() + tooltip_offset

func _init_tooltip_timer():
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = tooltip_delay_time
	tooltip_timer.one_shot = true
	tooltip_timer.connect("timeout", Callable(self, "_on_tooltip_timer_timeout"))
	add_child(tooltip_timer)

# Double click
func _init_click_timer():
	click_timer = Timer.new()
	click_timer.wait_time = DOUBLE_CLICK_DELAY
	click_timer.one_shot = true
	click_timer.connect("timeout", Callable(self, "_reset_click_count"))
	add_child(click_timer)

func _reset_click_count():
	click_count = 0

func _handle_double_click(event:InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		click_count += 1

		if click_count == 1:
			# Start timer for double click detection
			click_timer.start()
		elif click_count == 2:
			# Double click detected
			emit_signal("_on_double_clicked", self)
			click_count = 0
			click_timer.stop()

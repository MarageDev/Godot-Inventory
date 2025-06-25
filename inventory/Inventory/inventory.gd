extends Control
class_name Inventory

signal on_item_moved(from_slot: Slot, to_slot: Slot, moved_content: SlotContent)

@export var number_of_slots: int = 5
@export var slots_container: HFlowContainer

var slots: Array[Slot] = []

# SPLIT shared across the class
static var split_source_inventory: Inventory = null
static var split_from_slot: Slot = null
static var split_amount: int = 0
static var is_split_mode: bool = false
static var is_split_mode_key_held: bool = false

# PREVIEW
var preview_node: Control = null
var preview_content: SlotContent = null

@export var background_panel: Panel
@onready var margin_container: MarginContainer = $MarginContainer


func _ready() -> void:
	_set_up_inventory()
	_connect_signals_local()

var bounding_box:Rect2
var background_panel_margin:float = 10

func _process(delta: float) -> void:
	_update_background_panel()

func _update_background_panel():
	# Get the bounding box of all children in slots_container
	var bounding_box = get_children_bounding_box(slots_container)
	# Grow the bounding box by the desired margin
	var dilated_rect = bounding_box.grow(background_panel_margin)
	# Set the background panel's position and size (relative to this node)
	background_panel.position = dilated_rect.position - global_position
	background_panel.size = dilated_rect.size

	margin_container.add_theme_constant_override("margin_left", background_panel_margin)
	margin_container.add_theme_constant_override("margin_top", background_panel_margin)
	margin_container.add_theme_constant_override("margin_right", background_panel_margin)
	margin_container.add_theme_constant_override("margin_bottom", background_panel_margin)

func _connect_signals_local():
	for i: Slot in slots:
		if i:
			i.connect("_on_drag_started", on_slot_drag_started)
			i.connect("_on_drag_ended", on_slot_drag_ended)
			i.connect("_on_clicked", on_slot_clicked)

func _set_up_inventory():
	add_to_group("inventories", true)
	if not slots_container:
		push_error("Slot container not assigned!")
		return

	for i in range(number_of_slots):
		var temp_slot: Slot = preload("res://Slots/Slot.tscn").instantiate()
		if temp_slot:
			slots_container.add_child(temp_slot)
			slots.append(temp_slot)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_CTRL:
		is_split_mode_key_held = event.is_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if is_split_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if split_from_slot and split_from_slot in slots:
				is_split_mode = false
				clear_preview()
				var moved = SlotContent.new().convert_items_to_slot_content(split_from_slot.slot_content.content.slice(0, split_amount))
				emit_signal("on_item_moved", split_from_slot, null, moved)

func on_slot_drag_started(from_slot: Slot):
	if from_slot and not from_slot.slot_content.is_empty():
		preview_content = from_slot.slot_content
		display_preview()

func on_slot_drag_ended(from_slot: Slot):
	if from_slot.slot_content.is_empty() : return
	clear_preview()
	var to_slot: Slot = _find_slot_under_mouse_global()
	var moved_content: SlotContent = from_slot.slot_content if from_slot else null
	if not moved_content:
		return
	if to_slot:
		if can_stack_with(to_slot, moved_content):
			var first_item = to_slot.slot_content.get_first_item()
			if first_item:
				var target_slot_available_amount: int = first_item.max_stack_amount - to_slot.slot_content.get_amount()
				to_slot.merge_content(moved_content.remove_amount(target_slot_available_amount))
				var moved = SlotContent.new().convert_items_to_slot_content(moved_content.content.slice(0, target_slot_available_amount))
				emit_signal("on_item_moved", from_slot, to_slot, moved)
		elif to_slot.slot_content.is_empty():
			emit_signal("on_item_moved", from_slot, to_slot, moved_content)
			to_slot.set_content(moved_content.remove_all())
		else:
			emit_signal("on_item_moved", from_slot, to_slot, to_slot.slot_content)
			swap_slots(to_slot, from_slot)
	else:
		emit_signal("on_item_moved", from_slot, null, moved_content)

func on_slot_clicked(slot: Slot):
	_handle_split_mode(slot)

func _handle_split_mode(slot: Slot):
	if not is_split_mode:
		split_amount = 0
		split_from_slot = slot
		if is_split_mode_key_held:
			is_split_mode = true
	if is_split_mode and slot == split_from_slot:
		if split_amount < slot.slot_content.get_amount():
			split_amount += 1
			preview_content = SlotContent.new()
			preview_content.content = slot.slot_content.content.slice(0, split_amount)
			display_preview()
	if is_split_mode and slot != split_from_slot:
		handle_split_logic(split_from_slot)
		split_amount = 0
		is_split_mode = false
		clear_preview()

func handle_split_logic(slot: Slot):
	var to_slot: Slot = _find_slot_under_mouse_global()
	var splitted_content: SlotContent = slot.slot_content if slot else null
	if not splitted_content:
		return
	if to_slot:
		if can_stack_with(to_slot, splitted_content):
			var first_item = to_slot.slot_content.get_first_item()
			if first_item:
				var target_slot_available_amount: int = first_item.max_stack_amount - to_slot.slot_content.get_amount()
				var moved_amount: int = clamp(split_amount, 0, target_slot_available_amount)
				to_slot.merge_content(splitted_content.remove_amount(moved_amount))
				var moved = SlotContent.new().convert_items_to_slot_content(splitted_content.content.slice(0, moved_amount))
				emit_signal("on_item_moved", split_from_slot, to_slot, moved)
		elif to_slot.slot_content.is_empty():
			to_slot.set_content(splitted_content.remove_amount(split_amount))
			var moved = SlotContent.new().convert_items_to_slot_content(splitted_content.content.slice(0, split_amount))
			emit_signal("on_item_moved", split_from_slot, to_slot, moved)

func select_random_item_from_db(db: Database) -> Item:
	if not db or db.database.is_empty():
		push_error("Database is empty or invalid!")
		return null
	return db.database[randi_range(0, db.database.size() - 1)].duplicate()

func add_item(item: Item):
	if not item:
		push_error("Tried to add null item to inventory")
		return null
	for i: Slot in slots:
		if i.slot_content.is_empty():
			return i.add_item(item.duplicate())
	return null

func get_first_empty_slot() -> Slot:
	for i: Slot in slots:
		if i.slot_content.is_empty():
			return i
	return null

func swap_slots(slot1: Slot, slot2: Slot):
	if not slot1 or not slot2:
		return
	var temp_slot1_content: Array[Item] = slot1.slot_content.content.duplicate()
	var temp_slot2_content: Array[Item] = slot2.slot_content.content.duplicate()
	slot2.slot_content.set_content(temp_slot1_content)
	slot1.slot_content.set_content(temp_slot2_content)

func _find_slot_under_mouse_local() -> Slot:
	var mouse_pos = get_viewport().get_mouse_position()
	for slot in slots:
		if slot and slot.get_global_rect().has_point(mouse_pos):
			return slot
	return null

func _find_slot_under_mouse_global() -> Slot:
	var mouse_pos = get_viewport().get_mouse_position()
	for inventory in get_tree().get_nodes_in_group("inventories"):
		for slot in inventory.slots:
			if slot and slot.get_global_rect().has_point(mouse_pos):
				return slot
	return null

func can_stack_with(to_slot: Slot, moved_content: SlotContent) -> bool:
	if to_slot and not to_slot.slot_content.is_empty() and moved_content and not moved_content.is_empty():
		var to_first = to_slot.slot_content.get_first_item()
		var moved_first = moved_content.get_first_item()
		if not to_first or not moved_first:
			return false
		if to_first.max_stack_amount == -1 or moved_first.max_stack_amount == -1:
			return false
		if to_first.title == moved_first.title:
			return true
	return false

func auto_sort():
	var all_items: Array[Item] = []
	for slot in slots:
		all_items.append_array(slot.slot_content.content)
		slot.slot_content.set_content([] as Array[Item])
	var item_occurrences = get_items_occurences(all_items)
	item_occurrences.sort_custom(func(a, b): return a[0].title < b[0].title)
	for entry in item_occurrences:
		var item = entry[0]
		var count = entry[1]
		add_item_amount_stacked(item.duplicate(), count)

func get_items_occurences(items: Array[Item]) -> Array:
	var counts := {}
	for item in items:
		if not item:
			continue
		var key = item.title
		if counts.has(key):
			counts[key][1] += 1
		else:
			counts[key] = [item.duplicate(), 1]
	return counts.values()

func add_item_amount_stacked(item: Item, amount: int):
	if not item:
		push_error("Tried to stack null item")
		return
	var rest: int = amount
	var slot: Slot = get_first_empty_slot()
	if not slot:
		push_error("No empty slot available for stacking")
		return
	if item.max_stack_amount > 0:
		while rest > 0 and slot:
			slot.add_item(item.duplicate())
			if slot.slot_content.get_amount() == slot.slot_content.get_first_item().max_stack_amount:
				slot = get_first_empty_slot()
			rest -= 1
	else:
		for x in range(rest):
			if not slot:
				break
			slot.add_item(item.duplicate())
			slot = get_first_empty_slot()

func display_preview():
	clear_preview()
	var preview_scene = preload("res://Preview/preview.tscn")
	if not preview_scene:
		push_error("Preview scene not found!")
		return
	var preview = preview_scene.instantiate()
	if not preview:
		push_error("Failed to instantiate preview scene!")
		return
	preview_node = preview
	get_tree().root.add_child(preview)
	preview.slot_content = preview_content
	if preview.has_method("_update_visuals"):
		preview._update_visuals()
	preview.global_position = get_global_mouse_position() - preview.size / 2.0

func clear_preview():
	if preview_node:
		preview_node.queue_free()
	preview_node = null

func get_children_bounding_box(parent: Control) -> Rect2:
	var rects:Array[Rect2] = []
	for child in parent.get_children():
		if child is Control:
			rects.append(Rect2(child.global_position, child.size))
	return rects.reduce(func(a, b): return a.merge(b))

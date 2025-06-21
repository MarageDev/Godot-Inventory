extends Control
class_name InventoryClass

@onready var grid_container: GridContainer = $GridContainer
@export var col_number: int = 5
@export var row_number: int = 5
@export_file("*.tscn") var slot_scene_path: String = "res://Inventory/Slots/slot.tscn"

var slots: Array[SlotNode] = []
var database: DatabaseResource = preload("res://Database/Showcase.tres")

func _ready() -> void:
	_init_inventory()

# --- Inventory Setup ---
func _init_inventory():
	grid_container.columns = col_number
	slots.clear()
	var slot_scene = load(slot_scene_path)
	for i in range(col_number * row_number):
		var slot: SlotNode = slot_scene.instantiate()
		grid_container.add_child(slot)
		slots.append(slot)

# --- Item Management ---
func add_item(item: ItemResource, use_smart_add: bool = false) -> int:
	if use_smart_add:
		return _smart_add_item(item)
	else:
		return _simple_add_item(item)

func _simple_add_item(item: ItemResource) -> int:
	for slot in slots:
		if slot.item == null:
			slot.item = item.duplicate()
			slot.amount = item.amount
			return item.amount
	return 0

func _smart_add_item(item: ItemResource) -> int:
	if item.is_stackable:
		return _add_stackable_item(item)
	else:
		return _add_non_stackable_item(item)

func _add_stackable_item(item: ItemResource) -> int:
	var to_add = item.amount
	var added = 0
	# 1. Stack to existing stacks
	for slot in slots:
		if slot.item and slot.item.title == item.title and slot.item.is_stackable:
			var can_stack = slot.item.max_stack_amount - slot.amount
			if can_stack > 0:
				var add_now = min(can_stack, to_add)
				slot.amount += add_now
				to_add -= add_now
				added += add_now
				if to_add <= 0:
					return added
	# 2. Add to empty slots
	for slot in slots:
		if slot.item == null:
			var add_now = min(item.max_stack_amount, to_add)
			slot.item = item.duplicate()
			slot.amount = add_now
			to_add -= add_now
			added += add_now
			if to_add <= 0:
				return added
	return added

func _add_non_stackable_item(item: ItemResource) -> int:
	for slot in slots:
		if slot.item == null:
			slot.item = item.duplicate()
			slot.amount = 1
			return 1
	return 0

func move_item(item: ItemResource, target_inventory: InventoryClass) -> int:
	if item.amount <= 0:
		return 0


	# Try to move as much as possible
	var item_copy = item.duplicate()
	var to_move = item.amount

	# Move not stackable items if there are slots remaining
	if target_inventory.has_empty_slot() and not item.is_stackable :
		return 1


	# Try to add to target
	item_copy.amount = to_move
	var actually_moved = target_inventory.add_item(item_copy, true) # smart add

	if actually_moved <= 0:
		return 0 # Nothing moved

	# Remove the moved amount from this inventory
	_remove_stackable_item(item, actually_moved)
	return actually_moved

# Helper: removes up to 'amount' of the given stackable item from this inventory
func _remove_stackable_item(item: ItemResource, amount: int) -> void:
	var to_remove = amount
	for slot in slots:
		if slot.item and slot.item.title == item.title:
			var remove_now = min(slot.amount, to_remove)
			slot.amount -= remove_now
			to_remove -= remove_now
			if slot.amount <= 0:
				slot.item = null
			if to_remove <= 0:
				break

# --- Slot Utilities ---
func get_slots() -> Array[SlotNode]:
	return slots

func has_empty_slot() -> bool:
	return slots.any(func(slot): return slot.item == null)

func is_slot_in_inventory(slot: SlotNode) -> bool:
	return slot in get_slots()

func can_add_to_inventory(item: ItemResource, amount: int = 1) -> bool:
	if not item.is_stackable and not has_empty_slot():
		return false
	for slot in slots:
		if slot.item and slot.item.title == item.title and slot.amount < slot.item.max_stack_amount:
			var available_space = slot.item.max_stack_amount - slot.amount
			if available_space >= amount:
				return true
	return false

# --- Database Utilities ---
func select_random_item_from_DB(db: DatabaseResource) -> ItemResource:
	var items: Array[ItemResource] = db.database
	return items[randi_range(0, items.size() - 1)]

# --- Auto Arrange and Sorting ---
func auto_arrange_items() -> void:
	var merged_items = _merge_items()
	_apply_items_to_slots(merged_items)

func _merge_items() -> Array[ItemResource]:
	var all_items = _gather_items()
	var stackables = _merge_stackable_items(all_items)
	var non_stackables = all_items.filter(func(item): return not item.is_stackable)
	return _sort_items(stackables + non_stackables)

func _gather_items() -> Array[ItemResource]:
	var items: Array[ItemResource] = []
	for slot in slots:
		if slot.item:
			var copy = slot.item.duplicate()
			copy.amount = slot.amount
			items.append(copy)
	return items

func _merge_stackable_items(items: Array[ItemResource]) -> Array[ItemResource]:
	var stack_map := {}
	for item in items:
		if item.is_stackable:
			if not stack_map.has(item.title):
				stack_map[item.title] = [item.duplicate(), 0]
			stack_map[item.title][1] += item.amount
	var stacks: Array[ItemResource] = []
	for key in stack_map:
		var proto = stack_map[key][0]
		var remaining = stack_map[key][1]
		while remaining > 0:
			var stack_amount = min(proto.max_stack_amount, remaining)
			var stack_item = proto.duplicate()
			stack_item.amount = stack_amount
			stacks.append(stack_item)
			remaining -= stack_amount
	return stacks

func _sort_items(items: Array[ItemResource]) -> Array[ItemResource]:
	if not database:
		push_error("Database not initialized for sorting")
		return items
	var db_indices = {}
	for i in range(database.database.size()):
		db_indices[database.database[i].title] = i
	items.sort_custom(func(a, b):
		var a_index = db_indices.get(a.title, -1)
		var b_index = db_indices.get(b.title, -1)
		if a_index == b_index:
			return a.amount > b.amount
		return a_index < b_index
	)
	return items

func _apply_items_to_slots(items: Array[ItemResource]) -> void:
	_clear_all_slots()
	for i in min(items.size(), slots.size()):
		slots[i].item = items[i]
		slots[i].amount = items[i].amount

func _clear_all_slots() -> void:
	for slot in slots:
		slot.item = null
		slot.amount = 0

# --- External Item Acceptance ---
func try_accept_external_item(item: ItemResource, amount: int) -> int:
	var item_copy = item.duplicate()
	item_copy.amount = amount
	return add_item(item_copy, true)

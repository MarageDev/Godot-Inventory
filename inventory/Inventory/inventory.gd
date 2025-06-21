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

func _init_inventory():
	grid_container.columns = col_number
	slots.clear()
	var slot_scene = load(slot_scene_path)
	for i in range(col_number * row_number):
		var slot: SlotNode = slot_scene.instantiate()
		grid_container.add_child(slot)
		slot.stack = StackItemResourceClass.new()
		slots.append(slot)

func add_item(item: ItemResource, use_smart_add: bool = false) -> int:
	if use_smart_add:
		return _smart_add_item(item)
	else:
		return _simple_add_item(item)

func _simple_add_item(item: ItemResource) -> int:
	for slot in slots:
		if slot.stack.is_empty():
			var stack = StackItemResourceClass.new()
			stack.items.append(item.duplicate())
			slot.stack = stack
			return 1
	return 0

func _smart_add_item(item: ItemResource) -> int:
	if item.is_stackable:
		return _add_stackable_item(item)
	else:
		return _add_non_stackable_item(item)

func _add_stackable_item(item: ItemResource) -> int:
	var to_add = 1
	var added = 0
	# Try to stack with existing stacks with same stats
	for slot in slots:
		if not slot.stack.is_empty():
			var first = slot.stack.get_first_item()
			if first and first.title == item.title and first.is_stackable and first.stats == item.stats and slot.stack.get_amount() < first.max_stack_amount:
				slot.stack.items.append(item.duplicate())
				slot._update_visuals()
				return 1
	# Add to empty slot
	for slot in slots:
		if slot.stack.is_empty():
			var stack = StackItemResourceClass.new()
			stack.items.append(item.duplicate())
			slot.stack = stack
			slot._update_visuals()
			return 1
	return 0

func _add_non_stackable_item(item: ItemResource) -> int:
	for slot in slots:
		if slot.stack.is_empty():
			var stack = StackItemResourceClass.new()
			stack.items.append(item.duplicate())
			slot.stack = stack
			slot._update_visuals()
			return 1
	return 0

func move_item(item: ItemResource, target_inventory: InventoryClass) -> int:
	# Find and remove item from this inventory, add to target
	for slot in slots:
		for i in range(slot.stack.items.size()):
			var it = slot.stack.items[i]
			if it == item:
				if target_inventory.add_item(item, true) > 0:
					slot.stack.items.remove_at(i)
					slot._update_visuals()
					return 1
	return 0

func get_slots() -> Array[SlotNode]:
	return slots

func has_empty_slot() -> bool:
	return slots.any(func(slot): return slot.stack.is_empty())

func is_slot_in_inventory(slot: SlotNode) -> bool:
	return slot in get_slots()

func can_add_to_inventory(item: ItemResource, amount: int = 1) -> bool:
	for slot in slots:
		if slot.stack.is_empty():
			return true
		if not slot.stack.is_empty():
			var first = slot.stack.get_first_item()
			if first and first.title == item.title and first.is_stackable and slot.stack.get_amount() < first.max_stack_amount:
				return true
	return false

func select_random_item_from_DB(db: DatabaseResource) -> ItemResource:
	var items: Array[ItemResource] = db.database
	return items[randi_range(0, items.size() - 1)]

func auto_arrange_items() -> void:
	var merged_stacks = _merge_items()
	_apply_stacks_to_slots(merged_stacks)

func _gather_items() -> Array[ItemResource]:
	var items: Array[ItemResource] = []
	for slot in slots:
		for i in slot.stack.items:
			items.append(i.duplicate())
	return items

# Only group by item title (type), ignoring stats
func _merge_items() -> Array[StackItemResourceClass]:
	var all_items = _gather_items()
	var group_map = {}

	# Group by title only
	for item in all_items:
		var key = item.title
		if not group_map.has(key):
			group_map[key] = []
		group_map[key].append(item)

	var stacks: Array[StackItemResourceClass] = []
	for key in group_map:
		var group = group_map[key]
		var proto = group[0]
		var max_stack = proto.max_stack_amount if proto.is_stackable else 1
		while group.size() > 0:
			var stack = StackItemResourceClass.new()
			for i in range(min(max_stack, group.size())):
				stack.items.append(group.pop_front())
			stacks.append(stack)
	return stacks

func _apply_stacks_to_slots(stacks: Array[StackItemResourceClass]) -> void:
	_clear_all_slots()
	for i in min(stacks.size(), slots.size()):
		slots[i].stack = stacks[i]
		slots[i]._update_visuals()

func _clear_all_slots() -> void:
	for slot in slots:
		slot.stack = StackItemResourceClass.new()
		slot._update_visuals()

func try_accept_external_stack(stack: StackItemResourceClass) -> int:
	# Try to add the whole stack to an empty slot, or merge if possible
	for slot in slots:
		# If slot is empty, just assign the stack
		if slot.stack.is_empty():
			slot.stack = stack
			slot._update_visuals()
			return stack.items.size()
		# If slot has the same item type and stacking is allowed, merge if possible
		var first = slot.stack.get_first_item()
		var new_first = stack.get_first_item()
		if first and new_first and first.title == new_first.title and first.is_stackable:
			var max_stack = first.max_stack_amount
			var can_add = max_stack - slot.stack.items.size()
			if can_add > 0:
				# Move as many as possible from stack to slot.stack
				var to_move = min(can_add, stack.items.size())
				for i in range(to_move):
					slot.stack.items.append(stack.items.pop_front())
				slot._update_visuals()
				if stack.items.size() == 0:
					return to_move
	# If not all items could be added, return how many were added
	return 0

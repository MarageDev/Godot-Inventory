extends Control
class_name InventoryClass

@onready var grid_container: GridContainer = $GridContainer
@export var col_number:int = 5
@export var row_number:int = 5
@export_file("*.tscn") var slot_node_path:String = "res://Inventory/Slots/slot.tscn"

var slots_nodes:Array[SlotNode] = []

var database:DatabaseResource = preload("res://Database/Showcase.tres")

func _ready() -> void:
	_set_up_inventory()

func _set_up_inventory():
	grid_container.columns = col_number
	for i in range(col_number * row_number):
		var temp_slot: SlotNode = load(slot_node_path).instantiate()
		grid_container.add_child(temp_slot)
		slots_nodes.append(temp_slot)

# Returns the amount of items actually added (can be less than item.amount)
func add_item(item: ItemResource, use_smart_add: bool = false) -> int:
	if not use_smart_add:
		for slot in slots_nodes:
			if slot.item == null:
				slot.item = item.duplicate()
				slot.amount = item.amount
				return item.amount
		return 0

	if item.is_stackable:
		var to_add = item.amount
		var added = 0
		# 1. Stack with existing stacks
		for slot in slots_nodes:
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
		for slot in slots_nodes:
			if slot.item == null:
				var add_now = min(item.max_stack_amount, to_add)
				slot.item = item.duplicate()
				slot.amount = add_now
				to_add -= add_now
				added += add_now
				if to_add <= 0:
					return added
		return added # Could not add all, return how much was added
	else:
		# Not stackable: add to first empty slot only
		for slot in slots_nodes:
			if slot.item == null:
				slot.item = item.duplicate()
				slot.amount = 1
				return 1
		return 0



func get_slots() -> Array[SlotNode]:
	return slots_nodes


func select_random_item_from_DB(db:DatabaseResource):
	var items:Array[ItemResource] = db.database
	return items[randi_range(0, items.size() - 1)]

func _auto_arrange_items() -> void:
	var merged_items := _get_merged_items()
	_apply_sorted_items_to_slots(merged_items)

func _get_merged_items() -> Array[ItemResource]:
	var all_items := _gather_all_items()
	var processed_items := _process_stackable_items(all_items)
	return _sort_items(processed_items)

func _gather_all_items() -> Array[ItemResource]:
	var collected :Array[ItemResource]= []
	for slot in slots_nodes:
		if slot.item:
			collected.append(_duplicate_item_with_amount(slot.item, slot.amount))
	return collected

func _duplicate_item_with_amount(source: ItemResource, amount: int) -> ItemResource:
	var duplicate := source.duplicate()
	duplicate.amount = amount
	return duplicate

func _process_stackable_items(items: Array[ItemResource]) -> Array[ItemResource]:
	var stacks := _create_item_stacks(items)
	return stacks + _get_non_stackables(items)

func _create_item_stacks(items: Array[ItemResource]) -> Array[ItemResource]:
	var stack_dict := {}  # Key: item.title, Value: Array[base_item, total_amount]
	for item in items:
		if item.is_stackable:
			_update_stack_dict(stack_dict, item)
	return _generate_final_stacks(stack_dict)

func _update_stack_dict(stack_dict: Dictionary, item: ItemResource) -> void:
	if not stack_dict.has(item.title):
		stack_dict[item.title] = [item.duplicate(), 0]
	stack_dict[item.title][1] += item.amount

func _generate_final_stacks(stack_dict: Dictionary) -> Array[ItemResource]:
	var stacks :Array[ItemResource]= []
	for key in stack_dict:
		var proto: ItemResource = stack_dict[key][0]
		var remaining: int = stack_dict[key][1]
		while remaining > 0:
			var stack_amount :int= min(remaining, proto.max_stack_amount)
			stacks.append(_create_stack_instance(proto, stack_amount))
			remaining -= stack_amount
	return stacks

func _create_stack_instance(prototype: ItemResource, amount: int) -> ItemResource:
	var stack := prototype.duplicate()
	stack.amount = amount
	return stack

func _get_non_stackables(items: Array[ItemResource]) -> Array[ItemResource]:
	return items.filter(func(item): return not item.is_stackable)

func _sort_items(items: Array[ItemResource]) -> Array[ItemResource]:
	if not database:
		push_error("Database not initialized for sorting")
		return items
	var db_indices := _create_database_index_map()
	items.sort_custom(func(a, b):
		var a_index = db_indices.get(a.title, -1)
		var b_index = db_indices.get(b.title, -1)
		if a_index == b_index:
			return a.amount > b.amount
		return a_index < b_index
	)
	return items

func _create_database_index_map() -> Dictionary:
	var index_map := {}
	for index in range(database.database.size()):
		var item := database.database[index] as ItemResource
		if item:
			index_map[item.title] = index
	return index_map

func _apply_sorted_items_to_slots(sorted_items: Array[ItemResource]) -> void:
	_clear_all_slots()
	for i in min(sorted_items.size(), slots_nodes.size()):
		var slot: SlotNode = slots_nodes[i]
		var item: ItemResource = sorted_items[i]
		slot.item = item
		slot.amount = item.amount

func _clear_all_slots() -> void:
	for slot in slots_nodes:
		slot.item = null
		slot.amount = 0

func has_remaining_slots()->bool:
	return not slots_nodes.all(func(slot): return slot.item != null)

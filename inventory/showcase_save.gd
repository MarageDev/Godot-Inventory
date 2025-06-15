extends Control

@onready var grid_container: GridContainer = $GridContainer
@export var col_number:int = 1
@export var row_number:int = 1
@export_file("*.tscn") var slot_node_path:String

var slots_nodes:Array[SlotNode] = []

var database = [preload("res://Database/Items/Test.tres"),
preload("res://Database/Items/Test2.tres"),
preload("res://Database/Items/Test3.tres")
]

func _ready() -> void:
	grid_container.columns = col_number
	for i in range(col_number * row_number):
		var temp_slot:SlotNode = load(slot_node_path).instantiate()
		grid_container.add_child(temp_slot)
		slots_nodes.append(temp_slot)
	for i in range(10):
		add_item(database[randi_range(0, database.size() - 1)])

func add_item(item:ItemResource):
	var first_empty_slot:SlotNode = null
	for i:SlotNode in slots_nodes:
		if i.item == null:
			first_empty_slot = i
			break
	if first_empty_slot:
		first_empty_slot.item = item

func _on_add_item_button_pressed() -> void:
	add_item(database[randi_range(0, database.size() - 1)])

func _on_auto_arrange_items_button_pressed() -> void:
	# Gather all items from slots
	var all_items : Array = []
	for slot in slots_nodes:
		if slot.item:
			# Duplicate to avoid reference issues
			var new_item = slot.item.duplicate()
			new_item.amount = slot.amount
			all_items.append(new_item)

	# Merge stackable items into stacks (respect max stack size)
	var stacks_dict : Dictionary = {}  # key: item.title, value: [item_resource, total_amount]
	var non_stackable : Array = []

	for item in all_items:
		if item.is_stackable:
			if not stacks_dict.has(item.title):
				stacks_dict[item.title] = [item, 0, item.max_stack_amount]
			stacks_dict[item.title][1] += item.amount
		else:
			non_stackable.append(item)

	var merged_items : Array = []
	# For each stackable type, split into stacks of max_stack_amount
	for key in stacks_dict.keys():
		var proto = stacks_dict[key][0]
		var total = stacks_dict[key][1]
		var max_stack = stacks_dict[key][2]
		while total > 0:
			var stack_amt = min(total, max_stack)
			var stack_item = proto.duplicate()
			stack_item.amount = stack_amt
			merged_items.append(stack_item)
			total -= stack_amt

	# Add non-stackable items
	merged_items.append_array(non_stackable)

	# Sort by database order, then by amount descending
	merged_items.sort_custom(func(a, b):
		var a_db_idx = -1
		var b_db_idx = -1
		for i in range(database.size()):
			if database[i].title == a.title:
				a_db_idx = i
			if database[i].title == b.title:
				b_db_idx = i
		if a_db_idx == b_db_idx:
			return a.amount > b.amount  # Descending by amount
		return a_db_idx < b_db_idx      # Ascending by database order
	)

	# Clear all slots
	for slot in slots_nodes:
		slot.item = null
		slot.amount = 0

	# Fill slots with sorted items
	for i in range(min(merged_items.size(), slots_nodes.size())):
		var slot = slots_nodes[i]
		slot.item = merged_items[i]
		slot.amount = merged_items[i].amount

	# Remaining slots stay empty
	for i in range(merged_items.size(), slots_nodes.size()):
		slots_nodes[i].item = null
		slots_nodes[i].amount = 0

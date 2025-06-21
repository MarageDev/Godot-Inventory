extends InventoryClass

@export var inventory_main: InventoryClass
@export var inventory_secondary: InventoryClass
@export var inventory_dropped: InventoryClass

var inventories:Array[InventoryClass] = []

var is_quick_inventory_switch: bool = false

func _ready() -> void:
	inventories = [inventory_main, inventory_secondary, inventory_dropped]
	for i in range(10):
		inventory_main.add_item(select_random_item_from_DB(database))
	for i in range(10):
		add_randomized_item_to_inventory(preload("res://Database/Items/Test4.tres"),inventory_main)
	for inv in inventories:
		for slot in inv.get_slots():
			slot.connect("item_dropped", _on_any_item_dropped)
			slot.connect("item_clicked_on", _on_item_clicked_on)

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for inv in inventories:
		for slot: SlotNode in inv.get_slots():
			if slot in inventory_dropped.get_slots():
				draw_circle(slot.global_position + slot.size / 2., 5., Color.RED, true)
	if is_quick_inventory_switch:
		draw_line(get_global_mouse_position(),inventory_main.global_position+inventory_main.size/2.,Color.GREEN,2)

func _on_any_item_dropped(source_slot: SlotNode, target_slot: SlotNode, stack: StackItemResourceClass, amount: int):
	if target_slot == null and not inventory_dropped.is_slot_in_inventory(source_slot):
		if stack and not stack.is_empty():
			var accepted = inventory_dropped.try_accept_external_stack(stack)
			if accepted == stack.items.size():
				# All items moved, clear source
				source_slot.stack = StackItemResourceClass.new()
			else:
				# Only some items moved, remove those from source
				for i in range(accepted):
					source_slot.stack.items.pop_front()
			source_slot._update_visuals()
		return


func _on_item_clicked_on(source_slot: SlotNode, stack: StackItemResourceClass, amount: int):
	var quick_switch_inventory_target:InventoryClass = inventory_main
	if is_quick_inventory_switch:
		if source_slot not in quick_switch_inventory_target.get_slots() and stack and not stack.is_empty():
			var initial_inventory:InventoryClass = source_slot.get_parent_inventory(inventories)
			for i in stack.items:
				initial_inventory.move_item(i,quick_switch_inventory_target)

func _on_add_random_item_button_g_pressed() -> void:
	inventory_main.add_item(select_random_item_from_DB(database))

func _on_auto_arrange_items_button_g_pressed() -> void:
	inventory_main.auto_arrange_items()

func _on_add_random_item_button_o_pressed() -> void:
	inventory_secondary.add_item(select_random_item_from_DB(database))

func _on_auto_arrange_items_button_o_pressed() -> void:
	inventory_secondary.auto_arrange_items()

func _on_auto_arrange_items_button_b_pressed() -> void:
	inventory_dropped.auto_arrange_items()

func _on_add_random_item_button_b_pressed() -> void:
	inventory_dropped.add_item(select_random_item_from_DB(database))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SHIFT and event.is_pressed():
		is_quick_inventory_switch = true
	elif event is InputEventKey and event.keycode == KEY_SHIFT and not event.is_pressed():
		is_quick_inventory_switch = false

func add_randomized_item_to_inventory(selected_item: ItemResource, target_inventory: InventoryClass):
	# Duplicate the item so we don't change the original
	var new_item: ItemResource = selected_item.duplicate(true)

	# Remove any existing DAMAGE stat
	for i in range(new_item.stats.size() - 1, -1, -1):
		if new_item.stats[i].stat == StatsResource.StatsEnum.DAMAGE:
			new_item.stats.remove_at(i)

	# Add new randomized DAMAGE stat
	var s: StatsResource = StatsResource.new()
	s.stat = StatsResource.StatsEnum.DAMAGE
	s.value = randi_range(0, 20)
	new_item.stats.append(s)

	# Add the item to the inventory
	target_inventory.add_item(new_item, false)

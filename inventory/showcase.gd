extends InventoryClass

@export var inventory_main: InventoryClass
@export var inventory_secondary: InventoryClass
@export var inventory_dropped: InventoryClass

var inventories:Array[InventoryClass] = []

var is_quick_inventory_switch: bool = false

func _ready() -> void:
	inventories = [inventory_main, inventory_secondary, inventory_dropped]
	for i in range(25):
		inventory_main.add_item(select_random_item_from_DB(database))
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

func _on_any_item_dropped(source_slot: SlotNode, target_slot: SlotNode, item: ItemResource, amount: int):
	if target_slot == null and not inventory_dropped.is_slot_in_inventory(source_slot):
		var accepted = inventory_dropped.try_accept_external_item(item, amount)
		source_slot.amount -= accepted
		if accepted == 0:
			source_slot.item = item
			source_slot.amount = amount
		elif source_slot.amount <= 0:
			source_slot.item = null
			source_slot.amount = 0
		return




func _on_item_clicked_on(source_slot: SlotNode, item: ItemResource, amount: int):
	# Quick move to main inventory
	var quick_switch_inventory_target:InventoryClass = inventory_main
	if is_quick_inventory_switch:
		if source_slot not in quick_switch_inventory_target.get_slots() and item != null:
			var initial_inventory:InventoryClass = source_slot.get_parent_inventory(inventories)
			initial_inventory.move_item(item,quick_switch_inventory_target)

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
	# Handle quick switch bool on SHIFT input
	if event is InputEventKey and event.keycode == KEY_SHIFT and event.is_pressed():
		is_quick_inventory_switch = true
	elif event is InputEventKey and event.keycode == KEY_SHIFT and not event.is_pressed():
		is_quick_inventory_switch = false

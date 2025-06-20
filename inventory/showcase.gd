extends InventoryClass

@export var inventory_main:InventoryClass
@export var inventory_secondary:InventoryClass
@export var inventory_dropped:InventoryClass

func _ready() -> void:
	for i in range(10):
		inventory_main.add_item(select_random_item_from_DB(database))
	for inv in [inventory_main, inventory_secondary, inventory_dropped]:
		for slot in inv.get_slots():
			slot.connect("item_dropped", _on_any_item_dropped)
			slot.connect("item_clicked_on",_on_item_clicked_on)

func _on_any_item_dropped(source_slot: SlotNode, target_slot: SlotNode, item: ItemResource, amount: int):
	if target_slot == null and not is_slot_in_inventory(source_slot, inventory_dropped) :
		var dropped_item = item.duplicate()
		dropped_item.amount = amount
		var added = inventory_dropped.add_item(dropped_item, true) # now returns actual amount added
		if added > 0:
			source_slot.amount -= added
			# If source is empty, clear item
			if source_slot.amount <= 0:
				source_slot.item = null




func _on_item_clicked_on(source_slot:SlotNode,item:ItemResource,amount:int):
	if is_quick_inventory_switch:
		if source_slot not in inventory_main.slots_nodes and item != null:
			source_slot.item = null
			inventory_main.add_item(item)

func _on_add_random_item_button_g_pressed() -> void:
	inventory_main.add_item(select_random_item_from_DB(database))


func _on_auto_arrange_items_button_g_pressed() -> void:
	inventory_main._auto_arrange_items()


func _on_add_random_item_button_o_pressed() -> void:
	inventory_secondary.add_item(select_random_item_from_DB(database))


func _on_auto_arrange_items_button_o_pressed() -> void:
	inventory_secondary._auto_arrange_items()


func _on_auto_arrange_items_button_b_pressed() -> void:
	inventory_dropped._auto_arrange_items()


func _on_add_random_item_button_b_pressed() -> void:
	inventory_dropped.add_item(select_random_item_from_DB(database))


var is_quick_inventory_switch:bool = false
func _unhandled_key_input(event: InputEvent) -> void:
	# Handle quick switch bool on SHIFT input
	if event is InputEventKey and event.keycode == KEY_SHIFT and event.is_pressed():
		is_quick_inventory_switch = true
	elif event is InputEventKey and event.keycode == KEY_SHIFT and not event.is_pressed():
		is_quick_inventory_switch = false

func is_slot_in_inventory(slot: SlotNode, inventory: InventoryClass) -> bool:
	return slot.get_parent().get_parent() == inventory

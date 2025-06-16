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

func _on_any_item_dropped(source_slot:SlotNode, target_slot: SlotNode, item: ItemResource, amount: int):
	if target_slot == null and source_slot not in inventory_dropped.slots_nodes and target_slot not in inventory_dropped.slots_nodes:
		source_slot.item = null
		inventory_dropped.add_item(item)
		print("ah")
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

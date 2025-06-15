extends InventoryClass

@export var inventory_main:InventoryClass
@export var inventory_secondary:InventoryClass
func _ready() -> void:
	for i in range(10):
		inventory_main.add_item(select_random_item_from_DB(database))



func _on_add_random_item_button_g_pressed() -> void:
	inventory_main.add_item(select_random_item_from_DB(database))


func _on_auto_arrange_items_button_g_pressed() -> void:
	inventory_main._auto_arrange_items()


func _on_add_random_item_button_o_pressed() -> void:
	inventory_secondary.add_item(select_random_item_from_DB(database))


func _on_auto_arrange_items_button_o_pressed() -> void:
	inventory_secondary._auto_arrange_items()

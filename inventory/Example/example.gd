extends Control

@export var ground_inventory: Inventory
@export var main_inventory: Inventory
@export var second_inventory: Inventory

func _on_button_pressed() -> void:
	main_inventory.auto_sort()

func _ready() -> void:
	main_inventory.connect("on_item_moved", test)
	add_items_to_inventories()


func test(from_slot:Slot, to_slot:Slot, moved_content:SlotContent) -> void:
	if to_slot == null: # dropped on the ground
		for i in moved_content.content :
			ground_inventory.add_item(i) # Add items to the ground inventory
		from_slot.slot_content.remove_content(moved_content.content) # Remove the items added to the ground inventory from the slotm


var db = preload("res://Example/Database/example_database.tres")
func add_items_to_inventories():
	var InventoryInstance:Inventory = Inventory.new()
	# Main
	for i in range(10):
		var item = InventoryInstance.select_random_item_from_db(db)
		main_inventory.add_item(item.randomize_stats())
	main_inventory.add_item_amount_stacked(InventoryInstance.select_random_item_from_db(db).randomize_stats(),20)

	# Secondary
	for i in range(10):
		var item = InventoryInstance.select_random_item_from_db(db)
		second_inventory.add_item(item.randomize_stats())

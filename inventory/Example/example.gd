extends Control

@export var ground_inventory: Inventory
@export var main_inventory: Inventory
@export var second_inventory: Inventory

var inventories:Array[Inventory] = []

var is_shift_pressed: bool = false
func _ready() -> void:
	inventories = get_all_inventories()

	for inventory:Inventory in inventories:
		inventory.connect("on_item_moved",on_item_moved)
		inventory.connect("on_slot_clicked",on_inventory_slot_clicked)

	add_items_to_inventories()

func on_item_moved(from_slot:Slot, to_slot:Slot, moved_content:SlotContent) -> void:
	if to_slot == null and from_slot not in ground_inventory.slots: # Dropped on the ground and was not dragged from ground inventory
		if ground_inventory.get_first_empty_slot() != null : # Check if there are remaining slots
			ground_inventory.get_first_empty_slot().set_content(moved_content.remove_all()) # Set the content of the first empty slot to the moved content and remove the items added to the ground inventory from the slot
			# Equivalent :
			# ground_inventory.get_first_empty_slot().set_content(moved_content.content)
			# from_slot.slot_content.remove_content(moved_content.content)

func on_inventory_slot_clicked(slot:Slot):
	var target_inventory:Inventory
	if is_shift_pressed :
		if slot in main_inventory.slots :
			target_inventory = second_inventory
		elif slot in second_inventory.slots :
			target_inventory = main_inventory
		elif slot in ground_inventory.slots :
			target_inventory = main_inventory

		var target_slot:Slot = target_inventory.get_first_empty_slot()
		if target_slot and not slot.slot_content.is_empty() :
			target_slot.set_content(slot.slot_content.remove_all())

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		is_shift_pressed = event.is_pressed()

var db = preload("res://Example/Database/example_database.tres")
func add_items_to_inventories():
	var InventoryInstance:Inventory = Inventory.new()
	# Main
	for i in range(10):
		var item = InventoryInstance.select_random_item_from_db(db)
		main_inventory.add_item(item.randomize_stats())
	main_inventory.add_item_amount_stacked(InventoryInstance.select_random_item_from_db(db).randomize_stats(),5)

	# Secondary
	for i in range(10):
		var item = InventoryInstance.select_random_item_from_db(db)
		second_inventory.add_item(item.randomize_stats())

func get_all_inventories()->Array[Inventory]:
	var invs:Array[Inventory]
	for inventory in get_tree().get_nodes_in_group("inventories"):
		invs.append(inventory)
	return invs

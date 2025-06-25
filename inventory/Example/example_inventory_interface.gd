extends Control

@export var target_inventory:Inventory
@onready var label: Label = $Panel/MarginContainer/VBoxContainer/Label
@export var title:String = ""
func _ready() -> void:
	label.text = title

var db = preload("res://Example/Database/example_database.tres")
func _on_add_item_button_pressed() -> void:
	var InventoryInstance:Inventory = Inventory.new()
	var item = InventoryInstance.select_random_item_from_db(db)
	target_inventory.add_item(item.randomize_stats())



func _on_clean_button_pressed() -> void:
	target_inventory.auto_sort()

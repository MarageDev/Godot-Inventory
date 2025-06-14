extends Control
class_name InventoryClass

@onready var grid_container: GridContainer = $GridContainer
@export var col_number:int = 1
@export var row_number:int = 1


@export_file("*.tscn") var slot_node_path:String

var slots_nodes:Array[SlotNode] = []


func _ready() -> void:
	grid_container.columns = col_number
	for i in range(col_number*row_number):
		var temp_slot:SlotNode = load(slot_node_path).instantiate()
		grid_container.add_child(temp_slot)
		slots_nodes.append(temp_slot)
var l = [preload("res://Items/Test.tres"),preload("res://Items/Test2.tres")]
func add_item(item:ItemResource):
	var first_empty_slot:SlotNode
	for i:SlotNode in slots_nodes:
		if i.item == null : first_empty_slot = i
	first_empty_slot.item = item


func _on_add_item_button_pressed() -> void:
	add_item(l[randi_range(0,len(l)-1)])

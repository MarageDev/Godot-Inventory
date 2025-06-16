extends Resource
class_name ItemResource

@export var title:String = "null"
@export var icon:Texture2D = Texture2D.new()
@export var description:String = "null"

@export var is_stackable:bool = false
@export var amount:int = -1
@export var max_stack_amount:int = -1

@export var stats: Array[StatsResource] = []

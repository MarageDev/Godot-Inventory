extends Resource
class_name Item

@export var title:String = "null"
@export var icon:Texture2D = Texture2D.new()
@export var description:String = "null"

@export var max_stack_amount:int = -1 ## Maximum number of similar items you can stack. If set to -1 : non stackable

@export var stats: Array[Stats] = [] as Array[Stats]

func randomize_stats():
	var new_stats: Array[Stats] = []
	for i in stats:
		if i == null:
			continue
		var new_stat = Stats.new()
		new_stat.stat = i.stat
		new_stat.value = randi_range(0, 100)
		new_stats.append(new_stat)
	stats = new_stats
	return self

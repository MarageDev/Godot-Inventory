extends Control
@onready var title_label: Label = $MarginContainer/MarginContainer/VBoxContainer/Title
@onready var description_label: Label = $MarginContainer/MarginContainer/VBoxContainer/Description
@onready var stats_label: Label = $MarginContainer/MarginContainer/VBoxContainer/Stats

func _update(title:String,description:String,stats:Dictionary):
	if not title_label or not description_label or not stats_label:
		await self.ready
	title_label.text = title
	description_label.text = description

	var formatted_stats:Array[String] = []
	for i in stats:
		var stat_value = stats[i]
		var formated_stat_value:String = ""
		if stat_value[0] != stat_value[1]: formated_stat_value = "[ "+str(stat_value[0])+" - "+str(stat_value[1]) + " ]"
		else :  formated_stat_value = str(stat_value[0])
		var s:String = Stats.new().retrieve_stats_enum_str(i) + " : " + formated_stat_value
		formatted_stats.append(s)
	stats_label.text= "\n".join(formatted_stats)

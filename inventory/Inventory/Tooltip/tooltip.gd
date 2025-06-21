extends Control
class_name TooltipNode

@onready var title_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/Title
@onready var description_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/Description
@onready var stats_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/Stats

func _update_tooltip(title,desc,stats:Array):
	if not title_label or not description_label or not stats_label:
		await self.ready
	title_label.text = title
	description_label.text=desc

	var formatted_stats:Array[String] = []
	for i in stats:
		var stat_value = i[1]
		var formated_stat_value:String = ""

		if stat_value is not Array :
			formated_stat_value = str(stat_value)
		else :
			formated_stat_value = "[ "+str(stat_value[0])+" - "+str(stat_value[1]) + " ]"
		var s:String = StatsResource.new().retrieve_stats_enum_str(i[0]) + " : " + formated_stat_value
		formatted_stats.append(s)
	stats_label.text= "\n".join(formatted_stats)

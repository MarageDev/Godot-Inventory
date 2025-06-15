extends Control
class_name TooltipNode

@onready var title_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/Title
@onready var description_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/Description
@onready var stats_label: Label = $MarginContainer/MarginContainer2/VBoxContainer/Stats


func _update_tooltip(title,desc,stats):
	if not title_label or not description_label or not stats_label:
		await self.ready
	title_label.text = title
	description_label.text=desc
	stats_label.text=stats

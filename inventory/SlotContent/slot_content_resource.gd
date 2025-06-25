extends Resource
class_name SlotContent

signal slot_content_changed(resource:SlotContent)

@export var content:Array[Item] = []

func sort_content():
	pass

func get_first_item()->Item:
	return content[0] if not is_empty() else null

func retrieve_first_item():
	return content.pop_back()

func get_amount():
	return content.size() if not is_empty() else 0

func is_empty():
	return content.size() == 0

func add_item(item:Item)->Item:
	var item_to_add:Item = item
	#item_to_add.randomize_stats() # WARNING
	content.append(item_to_add)
	emit_signal("slot_content_changed",self)
	return item_to_add

func get_global_resource()->Item:
	return get_first_item()

func remove_all()->Array[Item]:
	var temp_content:Array[Item] = content
	content = []
	#print_rich("[color=red]Removed all content from stack")
	emit_signal("slot_content_changed",self)
	return temp_content

func remove_amount(amount: int) -> Array[Item]:
	var to_remove:int = min(amount, content.size())
	var removed_items:Array[Item] = content.slice(0, to_remove)
	content = content.slice(to_remove) # Keep the rest
	#print_rich("[color=orange]Removed %d items from stack" % to_remove)
	emit_signal("slot_content_changed", self)
	return removed_items

func merge_content(content_to_merge:Array[Item])->Array[Item]:
	content.append_array(content_to_merge)
	emit_signal("slot_content_changed", self)
	return content

func set_content(new_content:Array[Item]):
	content = new_content
	emit_signal("slot_content_changed",self)

func get_stats_range():
	var stat_ranges := {}  # Dictionary: stat_type -> [min, max]

	for item: Item in content:
		for s: Stats in item.stats:
			if not stat_ranges.has(s.stat):
				stat_ranges[s.stat] = [s.value, s.value]
			else:
				stat_ranges[s.stat][0] = min(stat_ranges[s.stat][0], s.value)
				stat_ranges[s.stat][1] = max(stat_ranges[s.stat][1], s.value)

	return stat_ranges

func remove_content(content_to_remove: Array[Item]) -> Array[Item]:
	var new_content:Array[Item] = []
	for item in content:
		if item not in content_to_remove:
			new_content.append(item)
	set_content(new_content)
	return new_content

func convert_items_to_slot_content(items:Array[Item])->SlotContent:
	var temp_content:SlotContent = SlotContent.new()
	temp_content.content = items.duplicate(true)
	return temp_content

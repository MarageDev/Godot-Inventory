extends Control
class_name SlotNode

var item:ItemResource = null:
	set(value):
		item = value

		if value == null:
			$Panel/Amount.text = ""
			$Panel/Icon.texture = null
		else :
			$Panel/Icon.texture = value.icon
			amount = value.amount

var amount:int = 0:
	set(value):
		amount = value
		$Panel/Amount.text = str(value)
		if amount <= 0 :
			$Panel/Amount.text = ""
			item = null

func _can_drop_data(at_position: Vector2, data: Variant):
	if "item" in data:
		return is_instance_of(data.item, ItemResource)
	return false

func _drop_data(at_position: Vector2, data: Variant):
	var dropped_on_slot_item = item
	var dropped_on_slot_amount = amount
	var source_slot_item = data.item
	var source_slot_amount = data.amount

	# Merge (stack) if same item title
	if dropped_on_slot_item and source_slot_item and dropped_on_slot_item.title == source_slot_item.title:
		amount += source_slot_amount
		data.item = null
		data.amount = 0
	else:
		# Swap both item and amount
		item = source_slot_item
		amount = source_slot_amount
		data.item = dropped_on_slot_item
		data.amount = dropped_on_slot_amount




func _get_drag_data(at_position: Vector2):
	if item:
		var preview_texture:TextureRect = TextureRect.new()
		preview_texture.texture = item.icon
		preview_texture.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
		preview_texture.size = $Panel.size
		preview_texture.position = -preview_texture.size / 2.0

		var preview:Control = Control.new()
		preview.add_child(preview_texture)
		preview.modulate = Color(1.0, 1.0, 1.0, 0.5)
		set_drag_preview(preview)
	return self

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if amount > 0:
			amount -= 1

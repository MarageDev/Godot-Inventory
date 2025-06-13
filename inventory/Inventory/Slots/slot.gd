extends Control
class_name SlotNode

@export var item:ItemResource = null:
	set(value):
		item = value
		if value == null:
			$Panel/Amount.text = ""
			$Panel/Icon.texture = null
			return
		$Panel/Icon.texture = value.icon

@export var amount:int = 0:
	set(value):
		amount = value
		$Panel/Amount.text = str(value)
		if amount <= 0:
			item = null

func set_amount(value:int)->void:
	amount = value

func add_amount(value:int)->void:
	amount += value

func _can_drop_data(at_position: Vector2, data: Variant):
	if "item" in data:
		return is_instance_of(data.item, ItemResource)
	return false

func _drop_data(at_position: Vector2, data: Variant):
	var temp = item
	item = data.item
	data.item = temp

	temp = amount
	amount = data.amount
	data.amount = temp

func _get_drag_data(at_position: Vector2):
	if item:
		var preview_texture:TextureRect = TextureRect.new()

		preview_texture.texture = item.icon

		preview_texture.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
		preview_texture.size = $Panel.size
		preview_texture.position= -preview_texture.size/2.

		var preview:Control = Control.new()
		preview.add_child(preview_texture)
		set_drag_preview(preview)
	return self

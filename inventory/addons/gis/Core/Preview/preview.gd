extends Control

var slot_content:SlotContent = SlotContent.new()

func _update_visuals():
	$Panel/Icon.texture = slot_content.get_first_item().icon if slot_content and not slot_content.is_empty() else null
	$Panel/Amount.text = str(slot_content.get_amount()) if slot_content and slot_content.get_amount() > 1 else ""
	return

func _process(delta: float) -> void:
	global_position = get_viewport().get_mouse_position() - size/2.

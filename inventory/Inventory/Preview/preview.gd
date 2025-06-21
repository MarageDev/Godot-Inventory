extends Control
class_name PreviewNode

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

		if item.is_stackable == false :
			$Panel/Amount.text = ""
		if amount <= 0 :
			$Panel/Amount.text = ""
			item = null

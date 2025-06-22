extends Resource
class_name StackItemResourceClass

@export var items: Array[ItemResource] = []
#@export var item:I


func get_amount() -> int:
	return items.size()

func is_empty() -> bool:
	return items.is_empty()

func get_first_item() -> ItemResource:
	return items[0] if items.size() > 0 else null

func can_stack_with(other: ItemResource) -> bool:
	# Only stack if all relevant stats match, or customize as needed
	for i in items:
		if not i.is_stackable or i.title != other.title:
			return false
	# Example: don't stack if durability differs, or allow partial stacking if you wish
	return true

func try_stack(item: ItemResource, max_stack: int) -> int:
	# Returns how many were stacked
	if items.size() >= max_stack:
		return 0
	if items.size() == 0 or (items[0].title == item.title and items[0].is_stackable):
		items.append(item)
		return 1
	return 0

func remove_amount(amount: int) -> Array[ItemResource]:
	var removed: Array[ItemResource] = []
	for i in range(min(amount, items.size())):
		removed.append(items.pop_front())
	return removed

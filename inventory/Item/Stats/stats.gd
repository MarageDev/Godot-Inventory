extends Resource
class_name StatsResource


enum StatsEnum {
	NULL,
	DURABILITY,
	DAMAGE,
	HEAL,
}

@export var stat:StatsEnum = StatsEnum.NULL
@export var value:float = 0.

func retrieve_stats_enum_str(s:StatsEnum):
	if s == StatsEnum.DURABILITY :
		return "Durability"
	elif s == StatsEnum.DAMAGE :
		return "Damage"
	elif s == StatsEnum.HEAL :
		return "Heal"

extends SpinBox

@export var desc: SpinBox


func _ready() -> void:
	desc.value_changed.connect(func(new: int): set_value_no_signal(StateVars.font.bb.y - new))
	value_changed.connect(func(new: int): desc.set_value_no_signal(StateVars.font.bb.y - new))


func save() -> void:
	pass


func load() -> void:
	value = StateVars.font.bb.y - StateVars.font.desc

extends SpinFoc

@export var desc: SpinBox
@export var bb_y: SpinBox


func _ready() -> void:
	value_changed.connect(func(new: int): desc.set_value_no_signal(bb_y.value - new))
	desc.value_changed.connect(func(new: int): set_value_no_signal(bb_y.value - new))
	bb_y.value_changed.connect(func(new: int): value = new - desc.value)


func save() -> void:
	pass


func load() -> void:
	value = StateVars.font.bb.y - StateVars.font.desc

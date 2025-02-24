extends HBoxContainer

@export var spin_bb_x: SpinBox
@export var spin_bb_y: SpinBox


func save() -> void:
	StateVars.font.bb.x = spin_bb_x.value
	StateVars.font.bb.y = spin_bb_y.value


func load() -> void:
	spin_bb_x.value = StateVars.font.bb.x
	spin_bb_y.value = StateVars.font.bb.y

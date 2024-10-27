extends HBoxContainer

@export var spin_bb_off_x: SpinBox
@export var spin_bb_off_y: SpinBox


func save() -> void:
	StateVars.font.bb_off.x = spin_bb_off_x.value
	StateVars.font.bb_off.y = spin_bb_off_y.value


func restore() -> void:
	spin_bb_off_x.value = StateVars.font.bb_off.x
	spin_bb_off_y.value = StateVars.font.bb_off.y

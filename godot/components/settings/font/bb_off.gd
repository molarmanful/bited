extends HBoxContainer

@export var spin_bb_off_x: SpinBox
@export var spin_bb_off_y: SpinBox


func save() -> void:
	StateVars.font.bb_off.x = int(spin_bb_off_x.value)
	StateVars.font.bb_off.y = int(spin_bb_off_y.value)


func load() -> void:
	spin_bb_off_x.value = StateVars.font.bb_off.x
	spin_bb_off_y.value = StateVars.font.bb_off.y

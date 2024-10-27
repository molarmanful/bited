extends HBoxContainer

@export var spin_x: SpinBox
@export var spin_y: SpinBox


func save() -> void:
	StateVars.font.resolution.x = spin_x.value
	StateVars.font.resolution.y = spin_y.value


func restore() -> void:
	spin_x.value = StateVars.font.resolution.x
	spin_y.value = StateVars.font.resolution.y

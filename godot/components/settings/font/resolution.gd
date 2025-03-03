extends HBoxContainer

@export var spin_x: SpinBox
@export var spin_y: SpinBox


func save() -> void:
	StateVars.font.resolution.x = int(spin_x.value)
	StateVars.font.resolution.y = int(spin_y.value)


func load() -> void:
	spin_x.value = StateVars.font.resolution.x
	spin_y.value = StateVars.font.resolution.y

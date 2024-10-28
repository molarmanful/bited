extends HBoxContainer

@export var line_reg: LineEdit
@export var line_enc: LineEdit


func save() -> void:
	StateVars.font.ch_reg = line_reg.text
	StateVars.font.ch_enc = line_enc.text


func load() -> void:
	line_reg.text = StateVars.font.ch_reg
	line_enc.text = StateVars.font.ch_enc

extends SpinBox


func save() -> void:
	StyleVars.thumb_px_size = value
	StateVars.cfg.set_value("display", "table_cell_scale", int(value))


func load() -> void:
	value = StyleVars.thumb_px_size

extends SpinFoc


func save() -> void:
	StyleVars.grid_px_size = value


func load() -> void:
	value = StyleVars.grid_px_size_cor

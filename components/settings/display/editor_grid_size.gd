extends SpinBox


func save() -> void:
	StyleVars.grid_size = value


func load() -> void:
	min_value = StyleVars.grid_size_min
	value = StyleVars.grid_size_cor

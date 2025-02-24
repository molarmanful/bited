extends SpinFoc


func save() -> void:
	StyleVars.table_width = value


func load() -> void:
	value = StyleVars.table_width

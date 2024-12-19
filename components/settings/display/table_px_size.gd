extends SpinFoc


func save() -> void:
	StyleVars.thumb_px_size = value


func load() -> void:
	value = StyleVars.thumb_px_size

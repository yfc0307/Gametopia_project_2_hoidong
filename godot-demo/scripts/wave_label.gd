extends RichTextLabel
func set_wave_text(value: String) -> void:
	var formatted := "[hudwave]" + value + "[/hudwave]"
	if text != formatted: text = formatted

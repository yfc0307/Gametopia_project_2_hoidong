@tool
extends RichTextEffect
var bbcode := "hudwave"
var phase := 0.0
var amplitude := 2.4
var letter_phase := 0.75
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.offset.y += sin(phase - float(char_fx.relative_index) * letter_phase) * amplitude
	return true

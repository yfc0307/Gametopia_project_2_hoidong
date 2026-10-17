@tool
extends Control
## Identity is an instance property, never an inherited child-text override.
@export_enum("廿四味", "五花茶", "銀菊露", "雞骨草", "夏枯草") var tea_name: String = "廿四味":
	set(value):
		tea_name = value
		refresh_label.call_deferred()
func _ready() -> void:
	refresh_label()
func refresh_label() -> void:
	var label := get_node_or_null("Design/Tag/Name") as Label
	if label == null: return
	var characters := PackedStringArray()
	for character in tea_name: characters.append(character)
	label.text = "\n".join(characters)

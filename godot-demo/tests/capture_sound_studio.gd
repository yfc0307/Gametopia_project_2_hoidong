extends "res://tests/test_sound_integration.gd"
## Native-render capture of the exact tested studio states. Synthetic microphone
## input only; output is tests/artifacts/sound_*.png, never personal recordings.

func _want_capture() -> bool:
	return true

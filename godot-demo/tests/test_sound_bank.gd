extends SceneTree

const SoundBank = preload("res://scripts/sound_bank.gd")
const EXPECTED_IDS: Array[String] = ["ui_click", "pick_up", "drop_valid", "drop_return", "tea_pour", "egg_cook", "egg_transfer", "phone_restock", "restock_complete", "discard", "order_paid", "customer_leave", "day_closed", "shop_open", "tea_ready", "egg_ready", "fish_cook", "fish_spear", "skewer_ready", "upgrade_buy", "customer_arrive"]
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)


func _run() -> void:
	var temporary := "res://tests/sound_bank_test_%d" % OS.get_process_id()
	var buses_before := AudioServer.bus_count
	var bank := SoundBank.new()
	bank.storage_directory = temporary
	root.add_child(bank)
	_check(not bank.is_recording and bank._microphone == null and bank._capture == null, "Opening the bank never activates or creates a microphone")
	_check(AudioServer.bus_count == buses_before, "No capture bus is allocated until a player explicitly records")
	_check(bank.EFFECTS.size() == 21 and bank.ORIGINAL_DURATIONS.size() == 21, "Catalog contains exactly the live game events")
	var identifiers: Dictionary = {}
	var waveforms: Dictionary = {}
	var durations: Dictionary = {}
	for effect in bank.EFFECTS:
		_check(EXPECTED_IDS.has(effect.id), "Sound corresponds to a live game event: " + effect.id)
		_check(not identifiers.has(effect.id), "Sound ID is unique: " + effect.id)
		identifiers[effect.id] = true
		_check(not effect.title.is_empty() and not effect.trigger.is_empty() and not effect.idea.is_empty() and not effect.group.is_empty(), "Picker explains each sound, trigger and recording idea")
		var original: AudioStreamWAV = bank.get_sound(effect.id, true)
		_check(original != null and not original.data.is_empty() and original.get_length() > 0.1, "Original exists: " + effect.id)
		if original == null:
			continue
		_check(original.format == AudioStreamWAV.FORMAT_16_BITS and original.mix_rate == 22050, "Original uses standard PCM16 audio")
		var peak := 0
		for offset in range(0, original.data.size(), 2):
			peak = maxi(peak, absi(original.data.decode_s16(offset)))
		_check(peak > 500 and peak < 31000, "Original is audible without hard clipping: " + effect.id)
		_check(original.data.decode_s16(0) == 0 and original.data.decode_s16(original.data.size() - 2) == 0, "Original endpoints avoid clicks: " + effect.id)
		var fingerprint := original.data.hex_encode().sha256_text()
		_check(not waveforms.has(fingerprint), "Every event has a distinct original: " + effect.id)
		waveforms[fingerprint] = true
		durations[original.data.size()] = true
		_check(bank.get_sound(effect.id) == original, "Uncustomized event plays its original")
	_check(durations.size() >= 18, "Short interactions and longer preparation events have varied durations")
	_check(absf(bank.get_sound("tea_pour", true).get_length() - 1.2) < 0.001, "Tea pour has its 1.2-second duration")
	_check(absf(bank.get_sound("fish_spear", true).get_length() - 0.18) < 0.001, "Individual fish spear cue stays brief")
	_check(bank.get_sound("../escape") == null and bank.get_sound("missing") == null, "Invalid IDs cannot resolve audio or paths")
	_check(bank.get_devices().has("Default"), "Device picker has a default input choice")
	var rate := 22050
	var frames := PackedVector2Array()
	frames.resize(rate * 2)
	# Stereo phase inversion catches accidental mono cancellation during trimming.
	for i in range(int(rate * 0.75), int(rate * 1.15)):
		var amplitude := sin(TAU * 440.0 * float(i) / rate) * 0.3
		frames[i] = Vector2(amplitude, -amplitude * 0.5)
	var prepared: Dictionary = bank.prepare_recording(frames, rate)
	_check(prepared.ok, "Valid stereo recording is accepted")
	if prepared.ok:
		_check(prepared.trimmed_seconds > 0.74 and prepared.trimmed_seconds < 0.76, "Removes the long initial silence without clipping the attack")
		_check(prepared.duration > 0.40 and prepared.duration < 0.45, "Trims trailing silence with a short natural tail")
		var processed: AudioStreamWAV = prepared.stream
		_check(processed.stereo and processed.mix_rate == rate, "Preserves sample rate and stereo")
		_check(processed.data.decode_s16(0) == 0 and processed.data.decode_s16(2) == 0 and processed.data.decode_s16(processed.data.size() - 2) == 0, "Processed audio has soft, click-free edges")
		var original_tea := bank.get_sound("tea_pour", true)
		for id in EXPECTED_IDS:
			_check(bank.save_custom(id, processed) == OK and bank.has_custom(id), "Saves and activates custom effect: " + id)
		_check(bank.get_sound("tea_pour") == processed and bank.get_sound("tea_pour", true) == original_tea, "Override applies while original preview remains available")
		_check(bank.save_custom("tea_pour", processed) == OK, "Existing accepted custom recording can be replaced")
		_check(bank.save_custom("../escape", processed) == ERR_INVALID_PARAMETER, "Save rejects traversal identifiers")
		_check(bank.save_custom("tea_pour", null) == ERR_INVALID_PARAMETER and bank.get_sound("tea_pour") == processed, "Invalid replacement preserves prior accepted take")
		var reloaded := SoundBank.new()
		reloaded.storage_directory = temporary
		root.add_child(reloaded)
		for id in EXPECTED_IDS:
			_check(reloaded.has_custom(id), "Reloads saved event override: " + id)
		_check(absf(reloaded.get_sound("tea_pour").get_length() - processed.get_length()) < 0.002, "Reload preserves trimmed recording duration")
		_check(reloaded.reset_to_original("tea_pour") == OK and not reloaded.has_custom("tea_pour"), "Restore original removes only the selected override")
		_check(not FileAccess.file_exists(temporary.path_join("tea_pour.wav")), "Restore removes the selected saved file")
		_check(reloaded.has_custom("order_paid") and FileAccess.file_exists(temporary.path_join("order_paid.wav")), "Restore leaves other recordings unchanged")
		_check(reloaded.reset_to_original("tea_pour") == OK, "Restoring an already original effect is safe")
		_check(reloaded.reset_to_original("../escape") == ERR_INVALID_PARAMETER, "Restore rejects traversal identifiers")
		var again := SoundBank.new()
		again.storage_directory = temporary
		root.add_child(again)
		_check(not again.has_custom("tea_pour") and again.has_custom("order_paid"), "Restore persists after restart")
		again.queue_free()
		reloaded.queue_free()
		bank.play("order_paid")
		_check(bank._players[0].stream == processed, "Gameplay playback resolves the accepted custom stream")
		bank.play("tea_pour", true)
		_check(bank._players[1].stream == original_tea, "Explicit original preview bypasses the accepted override")
		bank.stop_playback()
		var previous_voice := bank._next_player
		bank.is_recording = true
		bank.play("ui_click")
		_check(bank._next_player == previous_voice, "Playback cannot contaminate an active recording")
		bank.is_recording = false
	var silence := PackedVector2Array()
	silence.resize(rate)
	_check(not bank.prepare_recording(silence, rate).ok, "Rejects silence")
	for i in range(silence.size()):
		silence[i] = Vector2(0.09, 0.09)
	_check(not bank.prepare_recording(silence, rate).ok, "Rejects steady DC input")
	silence[200] = Vector2(NAN, 0.0)
	_check(not bank.prepare_recording(silence, rate).ok, "Rejects malformed non-finite samples")
	_check(not bank.prepare_recording(PackedVector2Array([Vector2.ONE]), rate).ok, "Rejects an unusably short take")
	_check(not bank.prepare_recording(frames, 0).ok, "Rejects invalid sample rate")
	var long_take := PackedVector2Array()
	long_take.resize(rate * 9)
	for i in range(long_take.size()):
		long_take[i] = Vector2.ONE * sin(TAU * 300.0 * float(i) / rate) * 0.25
	var limited: Dictionary = bank.prepare_recording(long_take, rate)
	_check(limited.ok and limited.duration <= 8.0, "Processing enforces the eight-second cap")
	if AudioServer.get_driver_name() == "Dummy":
		_check(not bank.start_recording(), "Headless capture fails cleanly without requesting input")
		_check(not bank.last_recording_error.is_empty() and bank._microphone == null, "Unavailable capture provides a helpful error and creates no microphone")
	_check(not bank.finish_recording().ok, "Stopping while idle reports a helpful failure")
	# Allocate the recorder graph without ever calling its microphone player's play().
	# Inject synthetic frames to verify the real stop/finish cleanup path safely.
	bank._setup_microphone()
	_check(AudioServer.bus_count == buses_before + 1 and not bank._microphone.playing, "Prepared capture graph remains silent until explicitly started")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index(bank._bus_name)), "Capture bus is muted to prevent monitoring feedback")
	bank._sample_rate = rate
	bank._frames = frames
	bank.is_recording = true
	bank._process(8.0)
	_check(bank.recording_seconds == 8.0 and bank._capture_stopped and not bank._microphone.playing, "Eight-second cap stops input and keeps the take available for review")
	var finished: Dictionary = bank.finish_recording()
	_check(finished.ok and finished.duration < 0.45, "Finishing processes the retained take after automatic stop")
	_check(not bank.is_recording and bank._microphone == null and bank._capture == null and AudioServer.bus_count == buses_before, "Finish releases the microphone and muted capture bus")
	bank._setup_microphone()
	bank.is_recording = true
	bank.cancel_recording()
	_check(not bank.is_recording and bank.recording_seconds == 0.0 and bank.recording_level() == 0.0, "Cancel returns recording state to idle")
	_check(bank._microphone == null and bank._capture == null and AudioServer.bus_count == buses_before, "Cancel leaves no capture resources")
	bank.queue_free()
	await process_frame
	# Stopped playback handles are released by the audio mix thread.
	await create_timer(0.15).timeout
	for id in EXPECTED_IDS:
		for suffix in [".wav", ".pending.wav"]:
			var file := temporary.path_join(id + suffix)
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(file)
	if DirAccess.dir_exists_absolute(temporary):
		DirAccess.remove_absolute(temporary)
	_check(AudioServer.bus_count == buses_before, "Destroying the bank does not leak audio buses")
	print("Sound bank tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

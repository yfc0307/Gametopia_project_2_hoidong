extends Control
## The page layout is authored in sound_studio.tscn; only catalog rows are instanced.

signal back_requested

const EFFECT_ROW := preload("res://scenes/components/sound_effect_row.tscn")
const RECORDING_LIMIT := 8.0

var sound_bank: Node
var current_effect: Dictionary = {}
var record_state: String = "idle"
var candidate: AudioStreamWAV
var take_info: Dictionary = {}
var selected_device: String = "Default"
var _rows: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _opened := false

@onready var effects_list: VBoxContainer = $Sheet/Sidebar/Scroll/Effects
@onready var device_picker: OptionButton = $Sheet/Recorder/Idle/Devices
@onready var status_label: Label = $Sheet/Recorder/Status

func _ready() -> void:
	_rng.randomize()
	$Back.pressed.connect(_return_requested)
	$Sheet/Sidebar/PickAnother.pressed.connect(_pick_another)
	$Sheet/Original/PlayOriginal.pressed.connect(_preview_original)
	$Sheet/Original/PlaySaved.pressed.connect(_preview_saved)
	$Sheet/Original/Restore.pressed.connect(_restore_original)
	$Sheet/Recorder/Idle/Refresh.pressed.connect(_refresh_devices)
	$Sheet/Recorder/Idle/Record.pressed.connect(_begin_recording)
	$Sheet/Recorder/Recording/Stop.pressed.connect(_finish_recording)
	$Sheet/Recorder/Review/Preview.pressed.connect(_preview_candidate)
	$Sheet/Recorder/Review/Retake.pressed.connect(_begin_recording)
	$Sheet/Recorder/Review/Use.pressed.connect(_save_recording)
	$Sheet/Recorder/Saved/Yes.pressed.connect(_pick_another)
	$Sheet/Recorder/Saved/No.pressed.connect(_return_requested)
	device_picker.item_selected.connect(_device_selected)
	_refresh_state()

func open(bank: Node) -> void:
	close()
	sound_bank = bank
	_opened = true
	visible = true
	_build_rows()
	_refresh_devices()
	_pick_another()

func close() -> void:
	if _opened and is_instance_valid(sound_bank):
		sound_bank.cancel_recording()
		sound_bank.stop_playback()
	_opened = false
	candidate = null
	take_info.clear()
	record_state = "idle"
	visible = false

func _exit_tree() -> void:
	close()

func handle_focus_lost() -> void:
	if not _opened or not is_instance_valid(sound_bank):
		return
	sound_bank.stop_playback()
	if record_state == "recording":
		sound_bank.cancel_recording()
		candidate = null
		take_info.clear()
		record_state = "idle"
		status_label.text = "視窗離開焦點，錄音已停止。準備好後可重新錄音。"
		_refresh_state()

func _process(_delta: float) -> void:
	if not _opened or record_state != "recording" or not is_instance_valid(sound_bank):
		return
	var seconds: float = minf(float(sound_bank.recording_seconds), RECORDING_LIMIT)
	$Sheet/Recorder/Recording/Elapsed.text = "REC  %.1f / 8.0 秒" % seconds
	$Sheet/Recorder/Recording/Duration.value = seconds
	$Sheet/Recorder/Recording/Level.value = sound_bank.recording_level()
	if seconds >= RECORDING_LIMIT:
		_finish_recording()

func _build_rows() -> void:
	for child in effects_list.get_children():
		effects_list.remove_child(child)
		child.queue_free()
	_rows.clear()
	var groups: Array[String] = []
	for entry in sound_bank.EFFECTS:
		var group := str(entry.get("group", "音效"))
		if not groups.has(group):
			groups.append(group)
	for group in groups:
		var first_in_group := true
		for entry in sound_bank.EFFECTS:
			var effect: Dictionary = entry
			if str(effect.get("group", "音效")) != group:
				continue
			var row := EFFECT_ROW.instantiate()
			row.get_node("Group").visible = first_in_group
			row.get_node("Group").text = group
			first_in_group = false
			var button: Button = row.get_node("Choice")
			var effect_id := str(effect["id"])
			button.text = str(effect["title"])
			button.tooltip_text = str(effect["trigger"])
			button.set_meta("effect_id", effect_id)
			button.pressed.connect(_select_effect.bind(effect_id))
			effects_list.add_child(row)
			_rows[effect_id] = button
	$Sheet/Sidebar/Count.text = "全部 %d 個音效" % _rows.size()

func _select_effect(effect_id: String) -> void:
	if not _opened:
		return
	var next_effect: Dictionary = {}
	for entry in sound_bank.EFFECTS:
		if str(entry["id"]) == effect_id:
			next_effect = entry.duplicate()
			break
	if next_effect.is_empty():
		return
	sound_bank.cancel_recording()
	sound_bank.stop_playback()
	current_effect = next_effect
	candidate = null
	take_info.clear()
	record_state = "idle"
	status_label.text = ""
	$Sheet/Original/Group.text = "01  /  " + str(current_effect.get("group", "音效"))
	$Sheet/Original/Title.text = str(current_effect["title"])
	$Sheet/Original/Trigger.text = str(current_effect["trigger"])
	$Sheet/Original/Idea.text = str(current_effect.get("idea", "試試用自己的聲音，創作一個短短的音效。"))
	_refresh_state()
	if _rows.has(effect_id):
		_reveal_effect.call_deferred(effect_id)

func _reveal_effect(effect_id: String) -> void:
	# Wait for native containers to arrange new rows, then use scroll-local units.
	# The main scene scales each page; global rectangles would overscroll here.
	await get_tree().process_frame
	if not _opened or not _rows.has(effect_id) or str(current_effect.get("id", "")) != effect_id:
		return
	var scroll: ScrollContainer = $Sheet/Sidebar/Scroll
	var row: Control = _rows[effect_id].get_parent()
	var top := row.position.y
	var bottom := top + row.size.y
	if top < scroll.scroll_vertical:
		scroll.scroll_vertical = int(floor(top))
	elif bottom > scroll.scroll_vertical + scroll.size.y:
		scroll.scroll_vertical = int(ceil(bottom - scroll.size.y))

func _pick_another() -> void:
	if not _opened:
		return
	var choices: Array[String] = []
	for entry in sound_bank.EFFECTS:
		var effect_id := str(entry["id"])
		if effect_id != str(current_effect.get("id", "")):
			choices.append(effect_id)
	if not choices.is_empty():
		_select_effect(choices[_rng.randi_range(0, choices.size() - 1)])

func _refresh_devices() -> void:
	if not is_instance_valid(sound_bank):
		return
	device_picker.clear()
	for device in sound_bank.get_devices():
		device_picker.add_item(str(device))
	var selected := -1
	for index in range(device_picker.item_count):
		if device_picker.get_item_text(index) == selected_device:
			selected = index
	if selected < 0 and device_picker.item_count > 0:
		selected = 0
	if selected >= 0:
		device_picker.select(selected)
		selected_device = device_picker.get_item_text(selected)
	$Sheet/Recorder/Idle/Record.disabled = device_picker.item_count == 0
	if device_picker.item_count == 0:
		status_label.text = "未找到麥克風。請連接麥克風，再按「重新整理」。"

func _device_selected(index: int) -> void:
	selected_device = device_picker.get_item_text(index)

func _begin_recording() -> void:
	if not _opened or current_effect.is_empty() or record_state == "recording":
		return
	sound_bank.stop_playback()
	candidate = null
	take_info.clear()
	status_label.text = ""
	if sound_bank.start_recording(selected_device):
		record_state = "recording"
		$Sheet/Recorder/Recording/Elapsed.text = "REC  0.0 / 8.0 秒"
		$Sheet/Recorder/Recording/Duration.value = 0
		$Sheet/Recorder/Recording/Level.value = 0
	else:
		record_state = "idle"
		status_label.text = str(sound_bank.last_recording_error)
	_refresh_state()

func _finish_recording() -> void:
	if not _opened or record_state != "recording":
		return
	take_info = sound_bank.finish_recording()
	if bool(take_info.get("ok", false)):
		candidate = take_info.get("stream") as AudioStreamWAV
		record_state = "review"
		$Sheet/Recorder/Review/Info.text = "音效長度：%.2f 秒\n已移除開頭 %.2f 秒的靜音。\n頭尾已柔化，播放更自然。" % [float(take_info.get("duration", 0)), float(take_info.get("trimmed_seconds", 0))]
		status_label.text = ""
	else:
		candidate = null
		record_state = "idle"
		status_label.text = str(take_info.get("message", "沒有錄到清楚的聲音，請檢查麥克風後再試。"))
	_refresh_state()

func _save_recording() -> void:
	if not _opened or record_state != "review" or candidate == null:
		return
	var error: int = sound_bank.save_custom(str(current_effect["id"]), candidate)
	if error != OK:
		status_label.text = "未能儲存錄音，請重試。原有音效仍然保留。"
		return
	sound_bank.stop_playback()
	candidate = null
	take_info.clear()
	record_state = "saved"
	status_label.text = ""
	$Sheet/Recorder/Saved/Effect.text = "「%s」已換成你的錄音。\n下次遊玩時就會聽到！" % str(current_effect["title"])
	_refresh_state()

func _preview_original() -> void:
	if _opened and record_state != "recording" and not current_effect.is_empty():
		sound_bank.stop_playback()
		sound_bank.play(str(current_effect["id"]), true)

func _preview_saved() -> void:
	if _opened and record_state != "recording" and not current_effect.is_empty():
		sound_bank.stop_playback()
		sound_bank.play(str(current_effect["id"]))

func _preview_candidate() -> void:
	if _opened and record_state == "review" and candidate != null:
		sound_bank.stop_playback()
		sound_bank.play_stream(candidate)

func _restore_original() -> void:
	if not _opened or record_state == "recording" or current_effect.is_empty():
		return
	var error: int = sound_bank.reset_to_original(str(current_effect["id"]))
	if error == OK:
		sound_bank.stop_playback()
		if record_state == "saved":
			record_state = "idle"
		status_label.text = "已還原預設音效。"
	else:
		status_label.text = "未能還原音效，請重試。你的錄音仍然保留。"
	_refresh_state()

func _refresh_state() -> void:
	$Sheet/Recorder/Idle.visible = record_state == "idle"
	$Sheet/Recorder/Recording.visible = record_state == "recording"
	$Sheet/Recorder/Review.visible = record_state == "review"
	$Sheet/Recorder/Saved.visible = record_state == "saved"
	var recording := record_state == "recording"
	var saved := is_instance_valid(sound_bank) and not current_effect.is_empty() and bool(sound_bank.has_custom(str(current_effect["id"])))
	$Sheet/Original/PlayOriginal.disabled = recording or current_effect.is_empty()
	$Sheet/Original/PlaySaved.disabled = recording or not saved
	$Sheet/Original/Restore.disabled = recording or not saved
	$Sheet/Original/SavedStatus.text = "目前使用：你的錄音" if saved else "目前使用：預設音效"
	for effect_id in _rows:
		var button: Button = _rows[effect_id]
		button.set_pressed_no_signal(effect_id == str(current_effect.get("id", "")))
		for effect in sound_bank.EFFECTS:
			if str(effect["id"]) == effect_id:
				button.text = ("✓ " if sound_bank.has_custom(effect_id) else "") + str(effect["title"])
				break

func _return_requested() -> void:
	close()
	back_requested.emit()

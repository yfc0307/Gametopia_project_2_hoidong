extends Node
## Local sound library and opt-in microphone recorder. No audio is transmitted.

const EFFECTS: Array[Dictionary] = [
	{"id": "ui_click", "group": "介面與營業", "title": "選單按鈕", "trigger": "選擇遊戲主介面的選單按鈕或確認選項時；自訂音效頁面選擇音效不會自動播放。", "idea": "試試輕輕的舌頭彈音，或一聲「好！」。"},
	{"id": "pick_up", "group": "拿取與放置", "title": "拿起物品", "trigger": "拿起茶壺、碗、雞蛋、食物或竹籤開始拖曳時。", "idea": "試試輕巧的「叮」或指尖輕敲聲。"},
	{"id": "drop_valid", "group": "拿取與放置", "title": "成功放置", "trigger": "拖曳的物品被製作設備、顧客或垃圾桶接受時。", "idea": "試試柔和的「篤」或陶瓷碰桌聲。"},
	{"id": "drop_return", "group": "拿取與放置", "title": "物品退回", "trigger": "物品放在不合適的位置、或送餐被拒絕而退回時。", "idea": "試試短短的「咦？」或向下滑的口哨。"},
	{"id": "tea_pour", "group": "涼茶", "title": "倒入涼茶", "trigger": "茶壺對準空碗開始倒茶時，或自動倒茶設備在成功送出或丟棄涼茶後重新填碗時。", "idea": "試試約一秒的「嘩啦、咕嚕嚕」倒水聲。"},
	{"id": "tea_ready", "group": "涼茶", "title": "涼茶倒好", "trigger": "手動或自動倒茶完成，一碗涼茶可以拿起供應時。", "idea": "試試兩個上揚的輕哼音，或「茶好啦！」。"},
	{"id": "egg_cook", "group": "茶葉蛋", "title": "開始煮蛋", "trigger": "把生雞蛋放進煮蛋鍋，開始烹煮時。", "idea": "試試低低的「卜卜卜」沸水聲。"},
	{"id": "egg_ready", "group": "茶葉蛋", "title": "茶葉蛋煮好", "trigger": "整批茶葉蛋煮熟、可以移到保溫鍋時。", "idea": "試試鍋蓋輕響，接著一聲「好啦！」。"},
	{"id": "egg_transfer", "group": "茶葉蛋", "title": "移入保溫鍋", "trigger": "點擊煮蛋鍋，開始將熟蛋移到保溫鍋時。", "idea": "試試幾聲柔和的「碌、碌、篤」。"},
	{"id": "fish_cook", "group": "魚蛋", "title": "開始煮魚蛋", "trigger": "生魚蛋放進辣味或原味湯鍋開始烹煮時。", "idea": "試試暖暖的「咕嚕、咕嚕」冒泡聲。"},
	{"id": "fish_spear", "group": "魚蛋", "title": "串起魚蛋", "trigger": "點擊一顆熟魚蛋，接受串起魚蛋的動作時。", "idea": "試試短促的「卜」或輕輕的啵啵聲。"},
	{"id": "skewer_ready", "group": "魚蛋", "title": "魚蛋串放好", "trigger": "魚蛋串完成串製並回到可拿取的位置時。", "idea": "試試木竹籤放下的「嗒」聲。"},
	{"id": "phone_restock", "group": "補貨", "title": "電話補貨", "trigger": "點擊電話並成功開始補貨時；存貨已滿不會播放。", "idea": "試試舊電話的「鈴鈴」聲，或一句「補貨呀！」。"},
	{"id": "restock_complete", "group": "補貨", "title": "補貨到達", "trigger": "補貨動畫結束，原料與現成食品補滿時。", "idea": "試試木箱落下的「喀咚」，再加輕輕的沙沙聲。"},
	{"id": "discard", "group": "拿取與放置", "title": "丟棄物品", "trigger": "把可丟棄的物品拖到垃圾桶並成功清除時。", "idea": "試試「唰、篤」或輕輕的垃圾桶蓋聲。"},
	{"id": "order_paid", "group": "顧客與收款", "title": "顧客完成付款", "trigger": "顧客的整張訂單完成並付款離開時。", "idea": "試試硬幣碰撞的「叮叮」聲，或「多謝！」。"},
	{"id": "customer_leave", "group": "顧客與收款", "title": "顧客失去耐性", "trigger": "顧客耐性用完，帶著尚未完成的訂單離開時。", "idea": "試試一聲短短的嘆氣或失望的「哦」。"},
	{"id": "customer_arrive", "group": "顧客與收款", "title": "顧客到訪", "trigger": "一位新顧客開始走進店舖時；點餐單會稍後出現。", "idea": "試試歡迎的「叮咚」或「你好呀！」。"},
	{"id": "day_closed", "group": "介面與營業", "title": "打烊鐘聲", "trigger": "營業倒數結束，店舖結算當日收入時。", "idea": "試試柔和的鐘聲，或一句「今日收工！」。"},
	{"id": "shop_open", "group": "介面與營業", "title": "開始營業", "trigger": "開始新一天並進入涼茶店營業畫面時。", "idea": "試試捲閘的「隆隆、喀」聲，或「開檔啦！」。"},
	{"id": "upgrade_buy", "group": "介面與營業", "title": "購買升級", "trigger": "成功購買設備升級或解鎖新食品時。", "idea": "試試開心的「鏘鏘」加一聲小敲擊。"},
]
const MAX_RECORDING_SECONDS: float = 8.0
const SYNTH_RATE: int = 22050
const ORIGINAL_DURATIONS: Dictionary = {
	"ui_click": 0.11,
	"pick_up": 0.23,
	"drop_valid": 0.28,
	"drop_return": 0.18,
	"tea_pour": 1.20,
	"tea_ready": 0.55,
	"egg_cook": 1.16,
	"egg_ready": 0.42,
	"egg_transfer": 0.40,
	"fish_cook": 1.05,
	"fish_spear": 0.18,
	"skewer_ready": 0.31,
	"phone_restock": 0.93,
	"restock_complete": 0.48,
	"discard": 0.20,
	"order_paid": 0.66,
	"customer_leave": 0.30,
	"customer_arrive": 0.85,
	"day_closed": 1.22,
	"shop_open": 0.82,
	"upgrade_buy": 0.88,
}

var is_recording: bool = false
var recording_seconds: float = 0.0
# Tests may select a separate temporary directory before adding this node.
var storage_directory: String = "user://custom_sfx_gametopia"
var last_recording_error: String = ""

var _originals: Dictionary = {}
var _custom: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _microphone: AudioStreamPlayer
var _capture: AudioEffectCapture
var _bus_name: String = ""
var _frames: PackedVector2Array = PackedVector2Array()
var _sample_rate: int = 44100
var _level: float = 0.0
var _discarded_at_start: int = 0
var _capture_stopped: bool = false


func _ready() -> void:
	for index in range(6):
		var player := AudioStreamPlayer.new()
		player.name = "SfxVoice%d" % index
		player.volume_db = -4.0
		add_child(player)
		_players.append(player)
	_load_customs()


func _process(delta: float) -> void:
	if not is_recording or _capture_stopped:
		return
	recording_seconds = minf(recording_seconds + delta, MAX_RECORDING_SECONDS)
	_drain_capture()
	if recording_seconds >= MAX_RECORDING_SECONDS:
		if _microphone != null:
			_microphone.stop()
		_capture_stopped = true
		_level = 0.0


func _exit_tree() -> void:
	stop_playback()
	cancel_recording()


func get_sound(id: String, original: bool = false) -> AudioStreamWAV:
	if not _valid_id(id):
		return null
	if not original and _custom.has(id):
		return _custom[id] as AudioStreamWAV
	if not _originals.has(id):
		_originals[id] = _synthesize(id)
	return _originals[id] as AudioStreamWAV


func play(id: String, original: bool = false) -> void:
	play_stream(get_sound(id, original))


func play_stream(stream: AudioStreamWAV) -> void:
	if stream == null or is_recording or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.play()


func stop_playback() -> void:
	for player in _players:
		player.stop()


func get_devices() -> PackedStringArray:
	var devices := PackedStringArray(["Default"])
	if AudioServer.get_driver_name() == "Dummy":
		return devices
	for device in AudioServer.get_input_device_list():
		if not devices.has(device):
			devices.append(device)
	return devices


func start_recording(device: String = "Default") -> bool:
	last_recording_error = ""
	if is_recording:
		last_recording_error = "請先完成或取消目前的錄音。"
		return false
	if AudioServer.get_driver_name() == "Dummy":
		last_recording_error = "無畫面模式無法使用麥克風。請正常開啟遊戲後錄音。"
		return false
	if not ProjectSettings.get_setting("audio/driver/enable_input", false):
		last_recording_error = "音訊輸入未開啟。請在專案設定啟用 Audio > Driver > Enable Input 並重新開啟遊戲。"
		return false
	if not get_devices().has(device):
		last_recording_error = "這支麥克風已中斷連線，請選擇其他輸入裝置。"
		return false
	if _microphone == null:
		_setup_microphone()
	stop_playback()
	AudioServer.input_device = device
	_sample_rate = int(AudioServer.get_mix_rate())
	_frames = PackedVector2Array()
	recording_seconds = 0.0
	_level = 0.0
	_capture_stopped = false
	_capture.clear_buffer()
	_discarded_at_start = _capture.get_discarded_frames()
	is_recording = true
	_microphone.play()
	return true


func finish_recording() -> Dictionary:
	if not is_recording:
		return _failure("目前沒有錄音。按下「開始錄音」製作新音效。")
	_drain_capture()
	var interrupted: bool = _capture != null and _capture.get_discarded_frames() > _discarded_at_start
	var result: Dictionary
	if interrupted:
		result = _failure("錄音曾經中斷，請重新錄製音效。")
	else:
		result = prepare_recording(_frames, _sample_rate)
	cancel_recording()
	return result


func cancel_recording() -> void:
	if _microphone != null:
		_microphone.stop()
		_microphone.stream = null
		_microphone.queue_free()
		_microphone = null
	if _capture != null:
		_capture.clear_buffer()
		_capture = null
	if not _bus_name.is_empty():
		var index := AudioServer.get_bus_index(_bus_name)
		if index >= 0:
			AudioServer.remove_bus(index)
		_bus_name = ""
	is_recording = false
	recording_seconds = 0.0
	_level = 0.0
	_capture_stopped = false
	_frames = PackedVector2Array()


func recording_level() -> float:
	return _level if is_recording else 0.0


func save_custom(id: String, stream: AudioStreamWAV) -> Error:
	if not _valid_id(id) or stream == null or stream.data.is_empty():
		return ERR_INVALID_PARAMETER
	if stream.format != AudioStreamWAV.FORMAT_16_BITS or stream.mix_rate <= 0 or stream.get_length() > MAX_RECORDING_SECONDS + 0.05:
		return ERR_INVALID_PARAMETER
	var directory_error := DirAccess.make_dir_recursive_absolute(storage_directory)
	if directory_error != OK:
		return directory_error
	var destination := storage_directory.path_join(id + ".wav")
	# A failed write must not replace a previously accepted recording.
	var temporary := storage_directory.path_join(id + ".pending.wav")
	var result := stream.save_to_wav(temporary)
	if result != OK:
		return result
	result = DirAccess.rename_absolute(temporary, destination)
	if result == OK:
		_custom[id] = stream
	return result


func reset_to_original(id: String) -> Error:
	if not _valid_id(id):
		return ERR_INVALID_PARAMETER
	var path := storage_directory.path_join(id + ".wav")
	if FileAccess.file_exists(path):
		var result := DirAccess.remove_absolute(path)
		if result != OK:
			return result
	_custom.erase(id)
	return OK


func has_custom(id: String) -> bool:
	return _custom.has(id)


func prepare_recording(frames: PackedVector2Array, sample_rate: int) -> Dictionary:
	## Pure DSP entry point: tests can exercise trimming without using a microphone.
	if sample_rate <= 0 or frames.size() < int(sample_rate * 0.10):
		return _failure("錄音太短了，請發出一段清楚的聲音再停止。")
	var count := mini(frames.size(), int(sample_rate * MAX_RECORDING_SECONDS))
	var dc := Vector2.ZERO
	for i in range(count):
		if not is_finite(frames[i].x) or not is_finite(frames[i].y):
			return _failure("錄音資料不完整，請重新錄製。")
		dc += frames[i]
	dc /= float(count)
	var peak: float = 0.0
	var window_size := maxi(1, int(sample_rate * 0.005))
	var energies := PackedFloat32Array()
	var square_sum: float = 0.0
	for i in range(count):
		var sample := frames[i] - dc
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		square_sum += (sample.x * sample.x + sample.y * sample.y) * 0.5
		if (i + 1) % window_size == 0 or i == count - 1:
			var window_count := window_size if (i + 1) % window_size == 0 else (i + 1) % window_size
			energies.append(sqrt(square_sum / float(window_count)))
			square_sum = 0.0
	if peak < 0.018:
		return _failure("沒有偵測到清楚的聲音。請檢查麥克風及 Windows 麥克風權限，再試一次。")
	var sorted_energies := energies.duplicate()
	sorted_energies.sort()
	var noise_floor: float = sorted_energies[int(sorted_energies.size() * 0.2)]
	var loudest: float = sorted_energies[sorted_energies.size() - 1]
	var threshold := maxf(0.008, minf(noise_floor * 3.0, loudest * 0.30))
	var first_window: int = -1
	var last_window: int = -1
	var active_windows: int = 0
	for i in range(energies.size()):
		if energies[i] >= threshold:
			if first_window < 0:
				first_window = i
			last_window = i
			active_windows += 1
	if first_window < 0 or active_windows * window_size < int(sample_rate * 0.020):
		return _failure("只偵測到很短的雜音。請錄製稍長、清楚一點的音效。")
	# Keep 3 ms before the first sound to preserve its attack, and a 25 ms tail.
	var first := first_window * window_size
	var search_end := mini(first + window_size, count)
	while first < search_end:
		var sample := frames[first] - dc
		if maxf(absf(sample.x), absf(sample.y)) >= threshold:
			break
		first += 1
	first = maxi(0, first - int(sample_rate * 0.003))
	var last := mini(count, (last_window + 1) * window_size + int(sample_rate * 0.025))
	var length := last - first
	if length < int(sample_rate * 0.045):
		return _failure("聲音太短，請錄製稍長一點的音效。")
	var data := PackedByteArray()
	data.resize(length * 4)
	var gain := minf(2.5, 0.80 / peak)
	var fade_in := maxi(1, int(sample_rate * 0.002))
	var fade_out := maxi(1, int(sample_rate * 0.005))
	for i in range(length):
		var envelope := minf(1.0, minf(float(i) / fade_in, float(length - 1 - i) / fade_out))
		var sample := (frames[first + i] - dc) * gain * envelope
		data.encode_s16(i * 4, int(clampf(sample.x, -1.0, 1.0) * 32767.0))
		data.encode_s16(i * 4 + 2, int(clampf(sample.y, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	stream.data = data
	return {
		"ok": true,
		"stream": stream,
		"message": "可以試聽了！已移除開頭與結尾的空白，並柔化聲音邊緣。",
		"trimmed_seconds": float(first) / sample_rate,
		"duration": float(length) / sample_rate,
	}


func _setup_microphone() -> void:
	_bus_name = "GametopiaMic_%d" % get_instance_id()
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, _bus_name)
	AudioServer.set_bus_mute(index, true)
	_capture = AudioEffectCapture.new()
	_capture.buffer_length = 1.0
	AudioServer.add_bus_effect(index, _capture)
	_microphone = AudioStreamPlayer.new()
	_microphone.name = "OptInMicrophone"
	_microphone.bus = _bus_name
	_microphone.stream = AudioStreamMicrophone.new()
	add_child(_microphone)


func _drain_capture() -> void:
	if _capture == null:
		return
	var available := _capture.get_frames_available()
	if available <= 0:
		_level *= 0.8
		return
	var chunk := _capture.get_buffer(available)
	var room := maxi(0, int(_sample_rate * MAX_RECORDING_SECONDS) - _frames.size())
	if chunk.size() > room:
		chunk.resize(room)
	_frames.append_array(chunk)
	var peak: float = 0.0
	for sample in chunk:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	_level = clampf(maxf(peak * 2.0, _level * 0.75), 0.0, 1.0)


func _load_customs() -> void:
	_custom.clear()
	var identifiers: Array[String] = []
	for effect in EFFECTS:
		identifiers.append(effect.id)
	for id in identifiers:
		var path := storage_directory.path_join(id + ".wav")
		if FileAccess.file_exists(path):
			var stream := AudioStreamWAV.load_from_file(path, {"force/max_rate": true, "force/max_rate_hz": 48000, "compress/mode": 0})
			if stream != null and not stream.data.is_empty() and stream.get_length() <= MAX_RECORDING_SECONDS + 0.05:
				_custom[id] = stream


func _valid_id(id: String) -> bool:
	for effect in EFFECTS:
		if effect.id == id:
			return true
	return false


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message, "trimmed_seconds": 0.0, "duration": 0.0}


func _synthesize(id: String) -> AudioStreamWAV:
	var duration: float = ORIGINAL_DURATIONS[id]
	var length := int(SYNTH_RATE * duration)
	var data := PackedByteArray()
	data.resize(length * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7229 + id.hash()
	var smooth_noise: float = 0.0
	var deep_noise: float = 0.0
	for i in range(length):
		var t := float(i) / SYNTH_RATE
		var noise := rng.randf_range(-1.0, 1.0)
		smooth_noise = smooth_noise * 0.65 + noise * 0.35
		deep_noise = deep_noise * 0.94 + noise * 0.06
		var dry_noise := noise - smooth_noise
		var value: float = 0.0
		match id:
			"ui_click":
				value = _wood(t, 680.0) * 0.42 + dry_noise * 0.11 * exp(-t * 125.0)
			"pick_up":
				value = _resonance(t, 1550.0, 65.0, 1.91) * 0.20 + _resonance(t - 0.046, 1340.0, 55.0, 1.84) * 0.18
				value += _drop(t - 0.075, 460.0) * 0.14
			"drop_valid":
				value = _wood(t, 165.0) * 0.28 + _resonance(t, 1310.0, 24.0, 1.89) * 0.22
			"drop_return":
				value = _wood(t, 580.0) * 0.28 + _wood(t - 0.065, 410.0) * 0.30
			"tea_pour":
				var flow := _pulse(t, 0.0, duration)
				value = (smooth_noise * 0.31 + dry_noise * 0.065) * flow
				for drop in range(12):
					value += _drop(t - drop * 0.113, 680.0 + drop * 34.0) * 0.085 * flow
			"tea_ready":
				value = _resonance(t, 783.99, 10.0, 2.0) * 0.22 + _resonance(t - 0.15, 987.77, 10.0, 2.0) * 0.24
			"egg_cook":
				value = (smooth_noise * 0.13 + deep_noise * 0.33) * _pulse(t, 0.0, duration)
				for bubble in range(11):
					value += _drop(t - bubble * 0.097, 145.0 + fmod(bubble * 47.0, 190.0)) * 0.14
			"egg_ready":
				value = _resonance(t, 310.0, 13.0, 2.57) * 0.32 + _resonance(t - 0.065, 685.0, 22.0, 2.1) * 0.10
				value += deep_noise * 0.30 * _pulse(t, 0.01, 0.22)
			"egg_transfer":
				for egg in range(5):
					value += _wood(t - egg * 0.045, 185.0 + egg * 53.0) * 0.16
				value += _resonance(t - 0.20, 640.0, 25.0, 2.2) * 0.10
			"fish_cook":
				value = (deep_noise * 0.32 + smooth_noise * 0.08) * _pulse(t, 0.0, duration)
				for bubble in range(9):
					var onset := bubble * 0.106 + sin(bubble * 2.1) * 0.019
					value += _drop(t - onset, 210.0 + fmod(bubble * 73.0, 290.0)) * 0.14
			"fish_spear":
				value = _drop(t, 440.0) * 0.35 + _wood(t - 0.055, 190.0) * 0.17 + smooth_noise * 0.09 * _pulse(t, 0.005, 0.16)
			"skewer_ready":
				value = _wood(t, 135.0) * 0.35 + _resonance(t, 1040.0, 23.0, 1.73) * 0.18
				value += _wood(t - 0.035, 250.0) * 0.12
			"phone_restock":
				# Two soft mechanical telephone rings, with a little handset click.
				var ringing := _pulse(t, 0.02, 0.30) + _pulse(t, 0.46, 0.30)
				var tremolo := 0.70 + 0.30 * sin(TAU * 23.0 * t)
				value = (sin(TAU * 810.0 * t) + sin(TAU * 1090.0 * t) * 0.65) * 0.17 * ringing * tremolo
				value += _wood(t - 0.83, 325.0) * 0.23
			"restock_complete":
				value = _wood(t, 148.0) * 0.34 + _wood(t - 0.29, 187.0) * 0.29
				value += (deep_noise * 0.37 + dry_noise * 0.12) * _pulse(t, 0.025, 0.36)
				value += _resonance(t - 0.31, 610.0, 25.0, 2.4) * 0.08
			"discard":
				value = dry_noise * 0.19 * _pulse(t, 0.0, 0.15) + _wood(t - 0.11, 118.0) * 0.34
			"order_paid":
				var coin_pitches := [2093.0, 2637.0, 1760.0, 2349.0]
				for coin in range(coin_pitches.size()):
					value += _resonance(t - coin * 0.092, coin_pitches[coin], 18.0, 1.47) * 0.19
			"customer_leave":
				var local := fmod(t, 0.15)
				var frequency := 330.0 if t < 0.15 else 261.63
				value = sin(TAU * frequency * local) * 0.32 * sin(PI * local / 0.15)
			"customer_arrive":
				value = _bell(t, 987.77) * 0.29 + _bell(t - 0.15, 739.99) * 0.26
			"day_closed":
				value = _bell(t, 659.25) * 0.28 + _bell(t - 0.27, 523.25) * 0.29 + _bell(t - 0.54, 392.0) * 0.27
			"shop_open":
				var slide := sin(PI * t / duration)
				value = (deep_noise * 0.48 + dry_noise * 0.08) * slide
				for step in range(7):
					value += _resonance(t - step * 0.085, 205.0 + step * 18.0, 30.0, 2.73) * 0.07
				value += _wood(t - 0.66, 130.0) * 0.35
			"upgrade_buy":
				value = _resonance(t, 1760.0, 16.0, 1.47) * 0.22 + _wood(t - 0.10, 390.0) * 0.17
				value += _bell(t - 0.20, 659.25) * 0.22 + _bell(t - 0.34, 987.77) * 0.25
		var envelope := minf(1.0, minf(t / 0.002, float(length - 1 - i) / (SYNTH_RATE * 0.008)))
		# Soft saturation keeps overlapping resonances comfortable without hard clipping.
		var mastered := tanh(value * 1.12) * 0.86 * envelope
		data.encode_s16(i * 2, int(mastered * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SYNTH_RATE
	stream.data = data
	return stream


func _bell(t: float, frequency: float) -> float:
	if t < 0.0:
		return 0.0
	return (sin(TAU * frequency * t) + sin(TAU * frequency * 2.003 * t) * 0.23) * exp(-t * 8.0) * minf(t / 0.004, 1.0)


func _resonance(t: float, frequency: float, decay: float, partial_ratio: float) -> float:
	if t < 0.0:
		return 0.0
	return (sin(TAU * frequency * t) + sin(TAU * frequency * partial_ratio * t) * 0.31) * exp(-t * decay) * minf(t / 0.0015, 1.0)


func _wood(t: float, frequency: float) -> float:
	if t < 0.0:
		return 0.0
	return (sin(TAU * frequency * t) + sin(TAU * frequency * 1.61 * t) * 0.32) * exp(-t * 48.0)


func _drop(t: float, frequency: float) -> float:
	if t < 0.0 or t > 0.18:
		return 0.0
	# A rapidly falling pitch and short hollow resonance resemble a small liquid drop.
	var phase := TAU * frequency * (t - 1.7 * t * t)
	return sin(phase) * exp(-t * 31.0) * minf(t / 0.004, 1.0)


func _pulse(t: float, start: float, duration: float) -> float:
	if t < start or t >= start + duration:
		return 0.0
	var position := (t - start) / duration
	return pow(maxf(0.0, sin(PI * position)), 0.55)

extends Node

const ES_SOCIAL_FEEDIA___HEYSON = preload("res://Music/ES_Social Feedia - Heyson.wav")

@onready var audio_stream_player: AudioStreamPlayer = $/root/Editor/AudioStreamPlayer
@onready var timer: Timer = $/root/Editor/AudioTimer
@onready var audio_spectrum_analyzer_instance: AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(0, 0)

@onready var cam: Camera = $/root/Editor/Misc/Cam

var music_move_intensity: float = 1;

var enabled: bool = false;
var choice: String = "None"

var SONGS = ["res://Music/ES_Social Feedia - Heyson.wav"];
var LOCALSONGS = [];

const SETTINGLIST = preload("res://Scenes/settings_list.tscn")

func _ready():
	play_random_song()

	audio_stream_player.finished.connect(check_choice)

	timer.timeout.connect(play_effects)

func check_choice() -> void:
	match choice:
		"None":
			return
		"Random":
			play_random_song()
		_:
			play_song(choice)

func play_random_song() -> void:
	if choice == "None": return

	var song = song_settings().slice(2).pick_random()

	play_song(song)

func play_song(song):
	if choice == "None": return
	var ind = song_settings().slice(2).find(song)
	if (ind == -1):
		print("WARNING: {} is not in settins".format(song))
		choice = "None"
		return
	timer.stop()
	audio_stream_player.stream = load_music(get_songs()[ind])
	audio_stream_player.play()
	timer.start()

func load_music(path:String) -> AudioStream:
	if path.begins_with("res://"):
		return load(path)
	var ext := path.get_extension().to_lower()
	if ext == "ogg":
		return AudioStreamOggVorbis.load_from_file(path)

	var res: AudioStream = {
	"mp3": AudioStreamMP3,
	"wav": AudioStreamWAV
	}[ext].new()

	if res is AudioStreamWAV:
		res.loop_mode = AudioStreamWAV.LOOP_DISABLED
		res.format = AudioStreamWAV.FORMAT_16_BITS
		res.stereo = true
	else:
		res.loop = false

	res.data = FileAccess.get_file_as_bytes(path)
	if res.data.size() < 1:
		print("WARNING: File {} is none".format(path))
	return res

func find_volume():
	var volume = audio_spectrum_analyzer_instance.get_magnitude_for_frequency_range(0.0, 20000, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX).length()
	return volume

func play_effects() -> void:
	if choice == "None": 
		audio_stream_player.stop()
		return timer.stop()
	var res = find_volume()
	
	cam.focus_temp(res * music_move_intensity * 10)

func set_volume(value: float) -> void:
	var clampedVolume = clamp(value, 0, 100)
	var decibels = lerp(-100, -30, 1 - (1 - clampedVolume / 100.0) ** 2)

	audio_stream_player.volume_db = decibels

func set_choice(value: String) -> void:
	choice = value;

	if !value:
		audio_stream_player.stop()
	else:
		check_choice()

func song_settings() -> Array:
	var sets = ["None","Random"]
	for i in get_songs():
		sets.append(i.get_file())
	return sets

func get_songs() -> Array:
	if LOCALSONGS.size() < 1:
		load_songs()
	var ln = []
	ln.append_array(SONGS)
	ln.append_array(LOCALSONGS)
	return ln

func load_songs() -> void:
	var dir = "user://music"
	if !DirAccess.dir_exists_absolute(dir):
		return 
	var n = DirAccess.get_files_at(dir)
	LOCALSONGS = []
	for i in n:
		var ex = i.get_extension().to_lower()
		if ex != "wav" and ex != "ogg" and ex != "mp3":
			continue
		LOCALSONGS.append(dir + "/" + i)

func try_add_item_to_setting(nod: Object) -> void:
	if (nod.name != "Settings"):
		return
	var cl = nod.get_children()[1].get_children()
	for i in cl:
		var label: RichTextLabel = i.get_node_or_null("Control/RichTextLabel");
		if label == null:
			continue
		#print(label.get_parsed_text())
		if "Music" not in label.get_parsed_text():
			continue
		for setting in LuaSingleton.settings:
			if setting.property == "music":
				var dropdown: OptionButton = i.get_node("Control5/OptionButton");
				if not dropdown.visible:
					break
				var lis = []
				Music.load_songs()
				for n in Music.song_settings():
					lis.append({"display": n,"value": n})
				setting.options = lis
				
				var txt = dropdown.get_item_text(dropdown.selected)
				if (txt != choice):
					txt = choice
				while dropdown.item_count > 2:
					dropdown.remove_item(2)
				var ind = 0
				var last_ind = -1
				for song in Music.get_songs():
					if song.get_file() == txt:
						last_ind = ind + 2
					dropdown.add_item(song.get_file())
					ind += 1
				if last_ind == -1:
					dropdown.selected = 0
				else:
					dropdown.selected = last_ind

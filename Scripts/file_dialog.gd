class_name FileDialogType

extends RichTextLabel

@onready var editor: FileManager = $".."
@onready var selected_panel: Panel = %SelectedPanel
@onready var code = %Code

var selected_index: int = 0
var dir: DirAccess
var dirs: Array[String]
var bbcode_dirs: Array[String]
var shortened_dirs: Array[String]
var files: Array[String]
var parsed_texts: PackedStringArray
var searched_inds: PackedInt32Array

var query: String = ""
var search_limit: int = 1000
var current_dirs_count: int = 0
var word_width = 0;
var handled: bool
var erased: bool
var max_coincidence: Array = []
var coincidence: Array = []

var isHighestFakeDir: bool = false
# if this is true, it will change logic in some functions

var zoom: Vector2;

var active: bool = false;
signal ui_close

func change_dir(path, no_change: bool=false) -> void:
	query = ""
	searched_inds = []
	if !dir: dir = DirAccess.open(path)
	#dir.include_hidden = true
	# WARNING: this will heavily affect performance if de-commented
	
	if isHighestFakeDir:
		dir = DirAccess.open(path)
		isHighestFakeDir = false

	if OS.get_name() == "Windows" and path == ".." and no_change:
		dirs = []
		for i in range(DirAccess.get_drive_count()):
			dirs.append(DirAccess.get_drive_name(i)+"\\")
		isHighestFakeDir = true
	else:
		dirs = [".."];
		dirs.append_array(dir.get_directories())
		dirs.append_array(dir.get_files())

	shortened_dirs = []
	for dir_ in dirs:
		if len(dir_) > 30:
			dir_ = dir_.left(30) + "..." + dir_.right(3)
		shortened_dirs.append(dir_)

	bbcode_dirs = []
	bbcode_dirs.append_array(dirs)

	current_dirs_count = len(dirs)

	files.append_array(dir.get_files())

	zoom = %Cam.to_zoom(code.get_longest_line(dirs).length())

	if active:
		%Cam.focus_on(gp(), zoom)

func setup() -> void:
	active = false
	change_dir(editor.current_dir)

	flush_items()

func _input(event: InputEvent) -> void:
	if !active: return
	if !(event is InputEventKey): return

	var key_event = event as InputEventKey
	bbcode_dirs = []
	bbcode_dirs.append_array(dirs)

	if !(key_event.is_pressed()): return;

	handled = true
	if key_event.keycode == KEY_UP:
		selected_index = max(0, selected_index - 1)
	elif key_event.keycode == KEY_DOWN:
		selected_index = min(len(dirs) - 1, selected_index + 1)
	elif key_event.keycode == KEY_ENTER:
		handle_enter_key()
	else:
		handled = false

	erased = false
	if current_dirs_count <= search_limit and !handled:
		if key_event.keycode == KEY_BACKSPACE:
			erased = true
			if len(query) > 0:
				query = query.substr(0, len(query) - 1)
		elif key_event.as_text() == 'Ctrl+Backspace':
			erased = true
			query = ""
		if len(key_event.as_text()) == 1:
			query += key_event.as_text().to_lower()
		elif key_event.keycode == KEY_PERIOD:
			query += "."
		searched_inds = []

	max_coincidence = []

	if len(query) > 0:
		for i in range(1, len(dirs)):
			coincidence = fuzzy_search(shortened_dirs[i].to_lower(), query)
			bbcode_dirs[i] = make_bold(shortened_dirs[i], coincidence)
			if (len(coincidence) > 0):
				searched_inds.append(i)
			if is_closer(max_coincidence, coincidence):
				max_coincidence = coincidence
				if not handled:	selected_index = i

	update_ui()

func flush_items() -> void:
	if len(dirs) >= 80 and !isHighestFakeDir:
		editor.warn(
			"[color=yellow]WARNING[/color] the items of {} are more then 80, there will disabled the search render"
			.format([dir.get_current_dir()],"{}")
		)
	clear()
	show_items()
	parsed_texts = get_parsed_text().split("\n")
	move_selected_panel()

func update_ui() -> void:
	if len(dirs) < 80 and !isHighestFakeDir:
		clear()
		show_items()
	move_selected_panel()
	if active: %Cam.focus_on(Vector2(gp().x, global_position.y + get_paragraph_offset(selected_index)), zoom)
	
func move_selected_panel() -> void:
	var off = Vector2(2,0)
	var selected_txt = parsed_texts[selected_index]
	if len(selected_txt) > 47: 
		selected_txt = selected_txt.substr(0,47)
	var reg = RegEx.new()
	reg.compile("g|j|q|y|p")
	if (reg.search(selected_txt)):
		off.y += 2
	if (reg.search(query) && len(dirs) < 80):
		off.y += 2
	var siz = get_theme_font("normal_font").get_string_size(selected_txt) + off
	var t = create_tween()
	var to = Vector2(-357-1, global_position.y + get_paragraph_offset(selected_index)-1) #magic -357
	var d = to.distance_to(selected_panel.position)
	var tm = clamp(d/30,0.01,0.1)
	t.parallel().tween_property(selected_panel,"position",to, tm)
	t.parallel().tween_property(selected_panel,"size",siz, tm)
	t.finished.connect(func():
		selected_panel.show_behind_parent = not active
	)
	var n = selected_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if (selected_index in searched_inds):
		n.border_color = Color.YELLOW
	else:
		n.border_color = Color.hex(0x00e7f3ff)
	
func show_items() -> void:
	for i in range(len(bbcode_dirs)):
		show_item(i)

func show_item(index: int) -> void:
	var item = dirs[index]
	var bbcode_item = bbcode_dirs[index]
	#if is_selected(item):
	#	push_bgcolor(LuaSingleton.gui.selection_color)
	#else:
	push_bgcolor(Color(0, 0, 0, 0))  # Reset background color if not selected

	var is_dir = dir.get_directories().find(item) != -1 or isHighestFakeDir

	if item == "..":
		push_color(LuaSingleton.gui.font_color)
		add_text("󰕌")
	elif is_dir:
		push_color(LuaSingleton.gui.completion_selected_color)
		add_text("")
	else:
		var extension = item.split(".")[-1]
		var data = Icons.get_icon_data(extension)

		push_color(Color.from_string(data.color, data.color))
		add_text(data.icon)

	pop()

	var filename = bbcode_item.split(".")[0]

	if is_dir: filename = bbcode_item


	if bbcode_item == "..":
		append_text(" %s\n" % [ bbcode_item ])
	elif is_dir or !item.contains("."):
		append_text(" %s\n" % [ filename ])
	else:
		append_text(" %s.%s\n" % [ filename, bbcode_item.split(".")[1] ])

# i gave up at that point, sorry for what you're about to witness
func is_selected(item: String) -> bool:
	var dir_item = dirs.find(item);

	var is_dir_item = dir_item != -1;
	var is_dir_current = dir_item == selected_index;

	return (is_dir_item and is_dir_current)

func handle_enter_key() -> void:
	if selected_index > len(dirs): return
	# ^^ this happens when the cursor was at, i.e., pos. 6, but arr is only has 4 entries

	var item = dirs[selected_index];

	var is_file = files.find(item) != -1;

	if is_file:
		editor.current_dir = dir.get_current_dir();
		editor.open_file(editor.current_dir + "/" + item)

		LuaSingleton.setup_extension(item.split(".")[-1])

		code.setup_highlighter()
		get_tree().create_timer(.1).timeout.connect(func():
			code.grab_focus()
		)

		ui_close.emit()
	else:
		selected_index = 0;
		var old_dir = DirAccess.open(dir.get_current_dir())
		dir.change_dir(item)
		change_dir(item, old_dir.get_current_dir() == dir.get_current_dir())
		flush_items()

func make_bold(string: String, indexes: Array) -> String:
	var new_string: String = ""

	for i in range(len(string)):
		if i in indexes: new_string += "[i][color=yellow]" + string[i] + "[/color][/i]"
		else: new_string += string[i]

	return new_string

func fuzzy_search(string: String, substring: String) -> Array:
	var indexes: Array = []
	var pos: int = 0
	var last_index: int = 0

	for i in range(string.length()):
		if string[i] == substring[pos]:
			indexes.append(i)
			pos += 1
			if pos == substring.length():
				break
		else:
			if last_index < i - 1:
				i = last_index
			pos = 0
			indexes = []

		last_index = i

	return indexes

# Compares 2 fuzzy Arrays and returns if 'new' Array is closer to query than 'old'
func is_closer(old: Array, new: Array) -> bool:
	if len(old) == 0: return true
	if len(new) == 0: return false

	if old == new: return false

	for i in range(len(old)):
		if old[i] > new[i]: return true
		elif old[i] < new[i]: return false

	return false

# global_position is slightly off, so we customize it a little.
func gp() -> Vector2:
	var vec = global_position;

	vec.x += 100;

	return vec;

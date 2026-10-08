extends CanvasLayer

const RADAR = preload("res://scripts/radar.gd")
var game: Node3D
var menu_panel: Control
var pause_panel: Control
var shop_panel: Control
var result_panel: Control
var scoreboard: Control
var scoreboard_text: Label
var stats: Label
var ammo_label: Label
var round_label: Label
var objective_label: Label
var message_label: Label
var kill_label: Label
var crosshair: Label
var hit_marker: Label
var hurt_overlay: ColorRect
var flash_overlay: ColorRect
var scope_overlay: Control
var difficulty: OptionButton
var sensitivity: HSlider
var volume: HSlider
var fullscreen: CheckBox
var radar: Control
var shop_open := false
var hurt_alpha := 0.0
var hit_left := 0.0
var message_left := 0.0
var kill_left := 0.0
var kill_lines: Array[String] = []
var start_buttons: Array[Button] = []
var ui_root: Control


func _ready() -> void:
	game = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root = Control.new()
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_status()
	_build_menu()
	_build_pause()
	_build_shop()
	_build_scoreboard()
	_build_result()
	_load_settings()
	close_panels()
	menu_panel.visible = true


func _style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _panel(width: float, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	ui_root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -width/2
	panel.offset_top = -height/2
	panel.offset_right = width/2
	panel.offset_bottom = height/2
	panel.add_theme_stylebox_override("panel",_style(Color(0.035,0.052,0.075,0.96),Color("344a5d")))
	return panel


func _label(parent: Node, text: String, size_value: int = 18, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size_value)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0,38)
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_stylebox_override("normal",_style(Color("162b3b"),Color("365369")))
	button.add_theme_stylebox_override("hover",_style(Color("28546a"),Color("8fc6bf")))
	button.add_theme_stylebox_override("pressed",_style(Color("38786f")))
	parent.add_child(button)
	button.pressed.connect(action)
	return button


func _build_menu() -> void:
	menu_panel = _panel(530,650)
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	menu_panel.offset_left = 55
	menu_panel.offset_top = -325
	menu_panel.offset_right = 585
	menu_panel.offset_bottom = 325
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	menu_panel.add_child(column)
	_label(column,"ATRIUM STRIKE",36,Color("e7c889"))
	_label(column,"CS uslubidagi mustaqil o‘yin · v0.1",16,Color("98b6c3"))
	_label(column,"Siz yuborgan 15 ta video asosidagi xarita.\nSiz + 7 bot, 5 g‘alabagacha. A/B bomba rejimi.",17)
	difficulty = OptionButton.new()
	for text in ["Oson botlar","O‘rtacha botlar","Qiyin botlar"]: difficulty.add_item(text)
	difficulty.selected = 1
	difficulty.custom_minimum_size.y = 34
	column.add_child(difficulty)
	start_buttons.append(_button(column,"CT bilan boshlash — himoya",func(): game.start_match(0,difficulty.selected)))
	start_buttons.append(_button(column,"T bilan boshlash — bomba",func(): game.start_match(1,difficulty.selected)))
	_button(column,"Xaritani erkin ko‘rish",game.explore_map)
	_label(column,"WASD · yurish   Space · sakrash   Ctrl · egilish\nShift · sekin yurish   R · qayta o‘qlash\n1/2/3/4 · qurol   B · xarid   E · bomba\nSichqoncha · otish   O‘ng tugma · sniper zoom\nTab · hisob   Esc · pauza",15,Color("b8c9d0"))
	var settings := HBoxContainer.new()
	column.add_child(settings)
	_label(settings,"Sichqoncha",15)
	sensitivity = HSlider.new()
	sensitivity.min_value = 0.5
	sensitivity.max_value = 2.5
	sensitivity.step = 0.1
	sensitivity.value = 1
	sensitivity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_child(sensitivity)
	var audio := HBoxContainer.new()
	column.add_child(audio)
	_label(audio,"Ovoz",15)
	volume = HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = 0.7
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio.add_child(volume)
	fullscreen = CheckBox.new()
	fullscreen.text = "To‘liq ekran (F11)"
	column.add_child(fullscreen)
	_button(column,"Chiqish",func(): get_tree().quit())


func _build_pause() -> void:
	pause_panel = _panel(440,305)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	pause_panel.add_child(column)
	_label(column,"PAUZA",28,Color("e7c889"))
	_button(column,"Davom etish",func(): game.set_paused(false))
	_button(column,"Yangi o‘yin",func(): game.set_paused(false); game.start_match(game.player.team,difficulty.selected))
	_button(column,"Asosiy menyu",game.return_to_menu)
	_button(column,"Chiqish",func(): get_tree().quit())


func _build_shop() -> void:
	shop_panel = _panel(650,510)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	shop_panel.add_child(column)
	_label(column,"QUROL XARIDI",28,Color("e7c889"))
	_label(column,"Dastlabki 20 soniya · boshlanish joyidan 12 metr",16,Color("a3bec8"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",10)
	column.add_child(grid)
	var items := [["AK-47 · $2700","ak"],["M4 · $3100","m4"],["MP5 · $1500","mp5"],["Sniper · $4750","awp"],["Shotgun · $1700","shotgun"],["Zirh · $650","armor"],["HE granata · $300","he"],["Flash · $200","flash"],["Smoke · $300","smoke"],["O‘qlar · $100","ammo"],["Defuse kit (CT) · $400","kit"]]
	for item in items:
		var button := _button(grid,item[0],game.buy.bind(item[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(column,"Yopish (B / Esc)",func(): toggle_shop())


func _build_status() -> void:
	round_label = _label(ui_root,"",24,Color("e7d5af"))
	round_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	round_label.offset_left = -170
	round_label.offset_top = 16
	round_label.size = Vector2(340,35)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label = _label(ui_root,"",16,Color("c1d1d8"))
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	objective_label.offset_left = -300
	objective_label.offset_top = 55
	objective_label.size.x = 600
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats = _label(ui_root,"",25,Color("b5dfd5"))
	stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stats.offset_left = 24
	stats.offset_top = -76
	ammo_label = _label(ui_root,"",24,Color("e7d5af"))
	ammo_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.offset_left = -320
	ammo_label.offset_top = -76
	ammo_label.size.x = 295
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	message_label = _label(ui_root,"",19,Color("edd8a3"))
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.offset_left = -510
	message_label.offset_top = -122
	message_label.size.x = 1020
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kill_label = _label(ui_root,"",16,Color("d9b787"))
	kill_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	kill_label.offset_left = -280
	kill_label.offset_top = 22
	kill_label.size.x = 260
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	crosshair = _label(ui_root,"+",28,Color("b4e5c4"))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -9
	crosshair.offset_top = -20
	hit_marker = _label(ui_root,"×",35,Color.WHITE)
	hit_marker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hit_marker.offset_left = -12
	hit_marker.offset_top = -24
	radar = Control.new()
	radar.set_script(RADAR)
	radar.position = Vector2(20,20)
	radar.size = Vector2(206,206)
	ui_root.add_child(radar)
	radar.game = game
	scope_overlay = Control.new()
	scope_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scope_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(scope_overlay)
	for horizontal in [true,false]:
		var line := ColorRect.new()
		line.color = Color(0,0,0,0.85)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scope_overlay.add_child(line)
		line.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		line.offset_left = -600 if horizontal else -1
		line.offset_top = -1 if horizontal else -350
		line.size = Vector2(1200,2) if horizontal else Vector2(2,700)
	hurt_overlay = ColorRect.new()
	hurt_overlay.color = Color(0.6,0.03,0.01,0)
	hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hurt_overlay)
	hurt_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay = ColorRect.new()
	flash_overlay.color = Color(1,1,1,0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(flash_overlay)
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_scoreboard() -> void:
	scoreboard = _panel(720,405)
	var column := VBoxContainer.new()
	scoreboard.add_child(column)
	_label(column,"HISOB / CT — T",28,Color("e7c889"))
	scoreboard_text = _label(column,"",19)


func _build_result() -> void:
	result_panel = _panel(530,260)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",15)
	result_panel.add_child(column)
	_label(column,"O‘YIN TUGADI",30,Color("e7c889"))
	_button(column,"Yana o‘ynash",func(): game.start_match(game.player.team,difficulty.selected))
	_button(column,"Asosiy menyu",game.return_to_menu)
	_button(column,"Chiqish",func(): get_tree().quit())


func close_panels() -> void:
	for panel in [menu_panel,pause_panel,shop_panel,result_panel,scoreboard]: panel.visible = false
	shop_open = false


func toggle_shop() -> void:
	if shop_open:
		shop_open = false
		shop_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif game.can_buy():
		shop_open = true
		shop_panel.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else: message("Xarid vaqti yoki boshlanish hududidan chiqdingiz.")


func message(text: String, duration: float = 3.0) -> void:
	message_label.text = text
	message_left = duration


func kill_notice(text: String) -> void:
	kill_lines.append(text)
	if kill_lines.size() > 4: kill_lines.pop_front()
	kill_label.text = "\n".join(kill_lines)
	kill_left = 7.0


func show_result(reason: String) -> void:
	result_panel.visible = true
	message(reason,60.0)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if shop_open: toggle_shop()
			elif game.phase != "menu": game.set_paused(not game.paused)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F11:
			fullscreen.button_pressed = not fullscreen.button_pressed


func _process(delta: float) -> void:
	var playing: bool = game.phase != "menu"
	for label in [stats,ammo_label,round_label,objective_label,radar]: label.visible = playing
	crosshair.visible = playing and not game.player.scoped and not game.paused and not shop_open and game.player.health > 0
	scope_overlay.visible = playing and game.player.scoped and game.player.health > 0
	hit_left = maxf(0,hit_left-delta)
	hit_marker.visible = hit_left > 0
	hurt_alpha = maxf(0,hurt_alpha-delta)
	hurt_overlay.color.a = hurt_alpha
	flash_overlay.color.a = clampf(game.player.flash_left/2.0,0,1)
	message_left = maxf(0,message_left-delta)
	message_label.visible = message_left > 0 and playing
	kill_left = maxf(0,kill_left-delta)
	kill_label.visible = kill_left > 0 and playing
	for button in start_buttons: button.disabled = not game.building.navigation_ready
	if not playing: return
	var p: Node3D = game.player
	stats.text = "HP %d   ZIRH %d\n$%d  ·  %s" % [p.health,p.armor,p.money,"CT" if p.team == 0 else "T"]
	var definition: Dictionary = game.WEAPONS.DATA[p.weapon]
	var ammo := ""
	if p.weapon == "knife": ammo = "Pichoq"
	elif p.weapon in ["he","flash","smoke"]: ammo = "%d dona" % p.grenades[p.weapon]
	else: ammo = "%d / %d" % [p.ammunition[p.weapon]["mag"],p.ammunition[p.weapon]["reserve"]]
	ammo_label.text = "%s\n%s" % [definition["name"],"QAYTA O‘QLASH..." if p.reload_left > 0 else ammo]
	var seconds := int(ceilf(maxf(0,game.bomb_left if game.bomb_planted else game.clock)))
	round_label.text = "CT %d    %02d:%02d    T %d" % [game.score[0],seconds/60,seconds%60,game.score[1]]
	if game.exploring:
		round_label.text = "XARITANI ERKIN KO‘RISH"
		objective_label.text = "F1–F4 · joylar   Esc · menyu"
	elif p.health <= 0: objective_label.text = "Yiqildingiz. Keyingi raundni kuting."
	elif game.phase == "freeze": objective_label.text = "TAYYORLANISH · B — qurol xaridi"
	elif game.bomb_planted: objective_label.text = "BOMBA O‘RNATILDI · CT: E bilan zararsizlantirish"
	else: objective_label.text = "A · atrium   B · orqa hovli" + ("   BOMBA SIZDA — E" if game.bomb_carrier == p else "")
	if game.interact_progress > 0: objective_label.text += "  [%.1f s]" % game.interact_progress
	if shop_open and not game.can_buy(): toggle_shop()
	scoreboard.visible = Input.is_action_pressed("scoreboard") and not game.paused
	if scoreboard.visible:
		var text := "JAMOA / ISM                     KILL / DEATH / HP\n"
		for actor in get_tree().get_nodes_in_group("combatants"):
			text += "%s / %-10s                       %d / %d / %d\n" % ["CT" if actor.team == 0 else "T",actor.actor_name,actor.kills,actor.deaths,actor.health]
		scoreboard_text.text = text


func _load_settings() -> void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	sensitivity.value = config.get_value("controls","sensitivity",1.0)
	volume.value = config.get_value("audio","volume",0.7)
	fullscreen.button_pressed = config.get_value("display","fullscreen",false)
	sensitivity.value_changed.connect(_save_settings)
	volume.value_changed.connect(_save_settings)
	fullscreen.toggled.connect(func(_value): _save_settings(0))
	_apply_settings()


func _apply_settings() -> void:
	game.player.mouse_sensitivity = 0.002 * sensitivity.value
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.001,volume.value)))
	get_window().mode = Window.MODE_FULLSCREEN if fullscreen.button_pressed else Window.MODE_WINDOWED


func _save_settings(_value: float) -> void:
	_apply_settings()
	var config := ConfigFile.new()
	config.set_value("controls","sensitivity",sensitivity.value)
	config.set_value("audio","volume",volume.value)
	config.set_value("display","fullscreen",fullscreen.button_pressed)
	config.save("user://settings.cfg")

extends Node2D

var DeckManager
var CharacterDatabase = preload("res://Scripts/CharacterDatabase.gd")
var CardDatabase = preload("res://Scripts/CardDatabase.gd")

var selected_deck_name = ""
var active_filter = "Mazos"
var solo_validos = false
const SAVE_PATH = "user://decks.json"
var all_decks = {}
var previewing_deck_name = ""
var is_dragging_scroll = false
var drag_start_y = 0.0
var scroll_start_y = 0.0
var drag_threshold = 10.0
var has_dragged = false

@onready var animacion = $AnimationPlayer
@onready var animacion_timer = $AnimacionTimer

@onready var deck_grid = $ScrollContainer/DeckGrid
@onready var mazos_button = $TopBar/FilterBar/MazosButton
@onready var favoritos_button = $TopBar/FilterBar/FavoritosButton
@onready var solo_validos_check = $TopBar/FilterBar/SoloValidosCheck2
@onready var scroll_container = $ScrollContainer
@onready var exit_button = $Responsive/HBoxContainer/Exit

func _ready():
	load_decks()
	
	mazos_button.pressed.connect(func(): set_filter("Mazos"))
	favoritos_button.pressed.connect(func(): set_filter("Favoritos"))
	solo_validos_check.toggled.connect(_on_solo_validos_toggled)
	exit_button.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/main.tscn"))
	
	# Scroll vertical únicamente
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	deck_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	await get_tree().process_frame
	scroll_container.get_v_scroll_bar().modulate = Color(0, 0, 0, 0)
	scroll_container.get_h_scroll_bar().modulate = Color(0, 0, 0, 0)
		
	populate_decks()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and scroll_container.get_global_rect().has_point(event.global_position):
			is_dragging_scroll = true
			has_dragged = false
			drag_start_y = event.global_position.y
			scroll_start_y = scroll_container.scroll_vertical
		else:
			is_dragging_scroll = false
	
	if event is InputEventMouseMotion and is_dragging_scroll:
		var delta = drag_start_y - event.global_position.y
		if abs(delta) > drag_threshold:
			has_dragged = true
			scroll_container.scroll_vertical = scroll_start_y + delta
			get_viewport().set_input_as_handled()

func load_decks():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var result = JSON.parse_string(content)
		if result:
			all_decks = result

func is_deck_valid(deck_name):
	if deck_name not in all_decks:
		return false
	var cards = all_decks[deck_name]["cards"]
	if cards.size() != 40:
		return false
	var card_counts = {}
	for card in cards:
		card_counts[card] = card_counts.get(card, 0) + 1
		if card_counts[card] > 4:
			return false
	return true

func set_filter(filtro: String):
	active_filter = filtro
	mazos_button.add_theme_color_override("font_color", Color(1, 1, 1))
	favoritos_button.add_theme_color_override("font_color", Color(1, 1, 1))
	if filtro == "Mazos":
		mazos_button.add_theme_color_override("font_color", Color(1, 0.9, 0))
	else:
		favoritos_button.add_theme_color_override("font_color", Color(1, 0.9, 0))
	populate_decks()

func _on_solo_validos_toggled(pressed: bool):
	solo_validos = pressed
	populate_decks()

func populate_decks():
	for child in deck_grid.get_children():
		child.queue_free()
	
	# Botón crear — fila propia centrada y grande
	var crear_hbox = HBoxContainer.new()
	crear_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	crear_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crear_hbox.add_child(_create_crear_button())
	deck_grid.add_child(crear_hbox)
	
	var deck_names = all_decks.keys()
	var filtered = []
	for deck_name in deck_names:
		if deck_name == "_selected":
			continue
		if solo_validos and not is_deck_valid(deck_name):
			continue
		if active_filter == "Favoritos":
			if not all_decks[deck_name].get("favorito", false):
				continue
		filtered.append(deck_name)
	
	filtered.reverse()
	
	var i = 0
	var fila = 0
	while i < filtered.size():
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 10)
		
		if fila % 2 == 0:
			# Fila de 2
			hbox.add_child(_create_deck_button(filtered[i]))
			i += 1
			if i < filtered.size():
				hbox.add_child(_create_deck_button(filtered[i]))
				i += 1
		else:
			# Fila de 1 centrado
			hbox.add_child(_create_deck_button(filtered[i]))
			i += 1
		
		fila += 1
		deck_grid.add_child(hbox)

func _create_crear_button() -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(500, 520)
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var tex = TextureRect.new()
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = load("res://UI/Mazos/VisualsDecks/HexCrear.png")
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex)
	
	var label = Label.new()
	label.text = "CREAR UN MAZO"
	label.position = Vector2(155, 340)
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	label.add_theme_color_override("font_color", Color(0.679, 0.024, 1.0))
	btn.add_child(label)
	
	btn.pressed.connect(func():
		print("CREAR MAZO PRESIONADO")
		animacion.play("Transicion")
		animacion_timer.start()
		await animacion_timer.timeout
		get_tree().change_scene_to_file("res://Scenes/deck_builder.tscn")
		
	)
	return btn


func _create_deck_button(deck_name: String) -> Button:
	var deck_data = all_decks[deck_name]
	var character_name = deck_data.get("character", "")
	var bando = ""
	if character_name != "" and character_name in CharacterDatabase.Characters:
		bando = CharacterDatabase.Characters[character_name]["bando"]
	
	var bando_assets = CharacterDatabase.BandoAssets.get(bando, CharacterDatabase.BandoAssets["Villano"])
	var selected_deck = all_decks.get("_selected", "")
	var is_active = selected_deck == deck_name
	var is_previewing = previewing_deck_name == deck_name
	
	var is_draft = not is_deck_valid(deck_name)

	
	
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(500, 500)
	btn.flat = true
	btn.clip_contents = false
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # ← aquí
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	
	# Hexágono base siempre igual
	var hex_tex = TextureRect.new()
	hex_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hex_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hex_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hex_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hex_key = "hex_draft" if is_draft else "hex"
	hex_tex.texture = load(bando_assets[hex_key])
	btn.add_child(hex_tex)
	
	# Overlay encima solo si está activo o en preview
	if is_active or is_previewing:
		var overlay = TextureRect.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.texture = load(bando_assets["hex_seleccionado"] if is_active else bando_assets["hex_preview"])
		btn.add_child(overlay)
	
	# Logo del personaje — centro del hexágono
	if character_name != "" and character_name in CharacterDatabase.Characters:
		var char_data = CharacterDatabase.Characters[character_name]
		var logo_tex = TextureRect.new()
		logo_tex.custom_minimum_size = Vector2(250, 250)
		logo_tex.position = Vector2(125, 80)
		logo_tex.size = Vector2(250, 250)
		logo_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo_tex.texture = load(char_data["logo"])
		btn.add_child(logo_tex)
	
	# Icono bando — abajo izquierda
	var bando_icon = TextureRect.new()
	bando_icon.custom_minimum_size = Vector2(80, 80)
	bando_icon.position = Vector2(90, 230)
	bando_icon.size = Vector2(80, 80)
	bando_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bando_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bando_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bando_icon.texture = load(bando_assets["icono_cartas"])
	btn.add_child(bando_icon)
	
	# Caja de cartas — abajo derecha
	var caja_tex = TextureRect.new()
	caja_tex.custom_minimum_size = Vector2(100, 130)
	caja_tex.position = Vector2(330, 180)
	caja_tex.size = Vector2(100, 130)
	caja_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	caja_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	caja_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_tex.texture = load(bando_assets["caja"])
	btn.add_child(caja_tex)
	
	# Nombre del deck — abajo centrado
	var label = Label.new()
	label.text = deck_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(40, 380)
	label.size = Vector2(400, 60)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_font_override("font", load("res://Cartas/Gill Sans Bold.otf"))
	if bando == "Heroe":
		label.add_theme_color_override("font_color", Color(0.43, 0.829, 1.0, 1.0))  # azul
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.0, 1.0)) 
	
	btn.add_child(label)
	
	
	btn.pressed.connect(func():
		print("deck seleccionado: ", deck_name)
		previewing_deck_name = deck_name
		populate_decks()
		#show_deck_preview(deck_name)
	)
	return btn

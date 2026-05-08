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



# panel para el Deck Preview
@onready var deck_preview_panel = $DeckPreviewPanel
@onready var drag_handle = $DeckPreviewPanel/DragHandle
@onready var favorito_button = $DeckPreviewPanel/FavoritoButton
@onready var delete_button = $DeckPreviewPanel/DeleteButton
@onready var deck_image_node = $DeckPreviewPanel/DeckImage
@onready var caja_cartas = $DeckPreviewPanel/DeckImage/CajaCartas
@onready var personaje_logo = $DeckPreviewPanel/DeckImage/PersonajeLogo
@onready var bando_icon = $DeckPreviewPanel/DeckImage/BandoIcon
@onready var deck_name_label = $DeckPreviewPanel/DeckName
@onready var card_count_label = $DeckPreviewPanel/CardCount
@onready var valid_label = $DeckPreviewPanel/ValidLabel
@onready var activar_button = $DeckPreviewPanel/ActivarButton
@onready var editar_button = $DeckPreviewPanel/EditarButton
@onready var cards_preview = $DeckPreviewPanel/CardsPreview
@onready var cards_grid = $DeckPreviewPanel/CardsPreview/CardsGrid
@onready var fondo_panel = $DeckPreviewPanel/FondoPanel

#-- para arrastrar el menu
var is_dragging_panel = false
var panel_drag_start_y = 0.0
var panel_start_pos_y = 0.0
const PANEL_Y_COLLAPSED = 1920.0
const PANEL_Y_MIN = 200.0  # hasta donde suben los filtros
#--
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

	# DeckPreviewPanel
	deck_preview_panel.position.y = PANEL_Y_COLLAPSED
	
	drag_handle.button_down.connect(_on_drag_handle_down)
	favorito_button.pressed.connect(_on_favorito_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	activar_button.pressed.connect(_on_activar_pressed)
	editar_button.pressed.connect(_on_editar_pressed)
	
	await get_tree().process_frame
	cards_preview.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_preview.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cards_preview.get_v_scroll_bar().modulate = Color(0, 0, 0, 0)
	cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_grid.custom_minimum_size.x = cards_preview.size.x


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

	#drag del panel del deck
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and scroll_container.get_global_rect().has_point(event.global_position):
			is_dragging_scroll = true
			has_dragged = false
			drag_start_y = event.global_position.y
			scroll_start_y = scroll_container.scroll_vertical
		elif not event.pressed:
			is_dragging_scroll = false
			is_dragging_panel = false
	
	if event is InputEventMouseMotion:
		if is_dragging_scroll:
			var delta = drag_start_y - event.global_position.y
			if abs(delta) > 10.0:
				scroll_container.scroll_vertical = scroll_start_y + delta
				get_viewport().set_input_as_handled()
		
		if is_dragging_panel:
			var delta = event.global_position.y - panel_drag_start_y
			var new_y = clamp(panel_start_pos_y + delta, PANEL_Y_MIN, PANEL_Y_COLLAPSED)
			deck_preview_panel.position.y = new_y

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
	
	# Ordena de más reciente a más antiguo
	filtered.sort_custom(func(a, b):
		var time_a = all_decks[a].get("created_at", 0)
		var time_b = all_decks[b].get("created_at", 0)
		return time_a > time_b
	)
	
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
		previewing_deck_name = deck_name
		populate_decks()
		show_deck_preview(deck_name)
	)
	return btn

#parte del deck preview

func show_deck_preview(deck_name: String):
	previewing_deck_name = deck_name
	selected_deck_name = deck_name
	populate_decks()
	
	var deck_data = all_decks[deck_name]
	var character_name = deck_data.get("character", "")
	var bando = ""
	if character_name != "" and character_name in CharacterDatabase.Characters:
		bando = CharacterDatabase.Characters[character_name]["bando"]
	
	var bando_assets = CharacterDatabase.BandoAssets.get(bando, CharacterDatabase.BandoAssets["Villano"])
	
	# Fondo del panel según bando
	if bando == "Heroe":
		fondo_panel.texture = load("res://UI/Mazos/VisualsDecks/FondoPanelHeroe.png")
	else:
		fondo_panel.texture = load("res://UI/Mazos/VisualsDecks/FondoPanelVillano.png")
	
	# DeckImage
	personaje_logo.texture = load(CharacterDatabase.Characters[character_name]["logo"]) if character_name in CharacterDatabase.Characters else null
	bando_icon.texture = load(bando_assets["icono_cartas"])
	caja_cartas.texture = load(bando_assets["caja"])
	
	# Info
	deck_name_label.text = deck_name
	var cards = deck_data.get("cards", [])
	card_count_label.text = "%d / 40" % cards.size()
	
	var valid = is_deck_valid(deck_name)
	if valid:
		valid_label.text = "✓ VALIDO"
		valid_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	else:
		valid_label.text = "✗ BORRADOR"
		valid_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	
	# Botón activar solo si es válido
	activar_button.disabled = not valid
	
	# Cartas del deck
	populate_cards_preview(deck_name)
	
	# Sube el panel
	var tween = create_tween()
	tween.tween_property(deck_preview_panel, "position:y", 900.0, 0.3).set_ease(Tween.EASE_OUT)

func populate_cards_preview(deck_name: String):
	for child in cards_grid.get_children():
		child.queue_free()
	
	var cards = all_decks[deck_name].get("cards", [])
	
	# Agrupa por nombre con conteo
	var card_counts = {}
	for card_name in cards:
		card_counts[card_name] = card_counts.get(card_name, 0) + 1
	
	for card_name in card_counts:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 220)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var tex = TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var card_image_path = "res://Cartas/%sCard.png" % card_name
		if ResourceLoader.exists(card_image_path):
			tex.texture = load(card_image_path)
		btn.add_child(tex)
		
		# Círculo con conteo
		var circle = Panel.new()
		circle.custom_minimum_size = Vector2(40, 40)
		circle.position = Vector2(90, 170)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.8)
		style.corner_radius_top_left = 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 20
		style.corner_radius_bottom_right = 20
		circle.add_theme_stylebox_override("panel", style)
		var count_label = Label.new()
		count_label.text = str(card_counts[card_name])
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		circle.add_child(count_label)
		btn.add_child(circle)
		
		cards_grid.add_child(btn)

# ── DRAG DEL PANEL ────────────────────────────────

func _on_drag_handle_down():
	is_dragging_panel = true
	panel_drag_start_y = get_viewport().get_mouse_position().y
	panel_start_pos_y = deck_preview_panel.position.y

func _on_favorito_pressed():
	if selected_deck_name == "":
		return
	var current = all_decks[selected_deck_name].get("favorito", false)
	all_decks[selected_deck_name]["favorito"] = not current
	_save_decks()
	favorito_button.text = "★" if not current else "☆"

func _on_delete_pressed():
	if selected_deck_name == "":
		return
	_show_confirm_dialog(
		"¿Eliminar este mazo? Esta acción no se puede deshacer.",
		func():
			_delete_deck(selected_deck_name)
			selected_deck_name = ""
			previewing_deck_name = ""
			var tween = create_tween()
			tween.tween_property(deck_preview_panel, "position:y", PANEL_Y_COLLAPSED, 0.3)
			populate_decks()
	)

func _on_activar_pressed():
	if selected_deck_name == "" or not is_deck_valid(selected_deck_name):
		return
	# Desactiva el anterior
	all_decks["_selected"] = selected_deck_name
	_save_decks()
	populate_decks()

func _on_editar_pressed():
	if selected_deck_name == "":
		return
	# Guarda el deck a editar en Global para que DeckBuilder lo recoja
	Global.deck_to_edit = selected_deck_name
	get_tree().change_scene_to_file("res://Scenes/DeckBuilder.tscn")

func _save_decks():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(all_decks))
		file.close()

func _delete_deck(deck_name: String):
	if deck_name in all_decks:
		all_decks.erase(deck_name)
		_save_decks()

func _show_confirm_dialog(message: String, action: Callable):
	var dialog = $ConfirmDialog
	dialog.visible = true
	dialog.get_node("Control/Message").text = message
	var confirm_btn = dialog.get_node("Control/ConfirmarButton")
	var cancel_btn = dialog.get_node("Control/CancelarButton")
	for c in confirm_btn.pressed.get_connections():
		confirm_btn.pressed.disconnect(c.callable)
	for c in cancel_btn.pressed.get_connections():
		cancel_btn.pressed.disconnect(c.callable)
	confirm_btn.pressed.connect(func():
		dialog.visible = false
		action.call()
	)
	cancel_btn.pressed.connect(func():
		dialog.visible = false
	)

extends Node2D

var deck_builder
var CardDatabase = preload("res://Scripts/CardDatabase.gd")
var CharacterDatabase = preload("res://Scripts/CharacterDatabase.gd")

var active_filter = "Tropas"
var collection_expanded = false
var available_cards = []
var selected_card_name = ""

# Posiciones del CollectionPanel
const PANEL_Y_COLLAPSED = 1700
const PANEL_Y_EXPANDED = 520

@onready var clase_icon1 = $Header/ClaseIcon1
@onready var clase_icon2 = $Header/ClaseIcon2
@onready var personaje_button = $Header/PersonajeButton
@onready var deck_name_edit = $DeckNameEdit
@onready var validate_button = $FilterBar/ValidateButton
@onready var tropas_button = $FilterBar/TropasButton
@onready var trucos_button = $FilterBar/TrucosButton
@onready var entornos_button = $FilterBar/EntornosButton
@onready var supports_button = $FilterBar/SupportButton
@onready var mazo_button = $FilterBar/MazoButton
@onready var deck_zone = $DeckZone
@onready var deck_grid = $DeckZone/DeckGrid
@onready var collection_panel = $CollectionPanel
@onready var drag_bar = $CollectionPanel/DragBar
@onready var search_bar = $CollectionPanel/LineEdit
@onready var search_button = $CollectionPanel/SearchButton
@onready var cartas_que_tienes = $CollectionPanel/CartasQueTienes
@onready var card_grid = $CollectionPanel/CardSection/CardGrid
@onready var card_preview = $CardPreview
@onready var background = $CardPreview/Background
@onready var card_display = $CardPreview/CardDisplay
@onready var label_ataque = $CardPreview/LabelAtaque
@onready var label_vida = $CardPreview/LabelVida
@onready var label_habilidad = $CardPreview/LabelHabilidad
@onready var copy_count = $CardPreview/CopyCount
@onready var add_button = $CardPreview/AddButton
@onready var remove_button = $CardPreview/RemoveButton
@onready var close_button = $CardPreview/CloseButton

@onready var animacion_timer = $"../PanelPersonaje/CharacterPreview/AnimacionTimer"
@onready var animacion = $"../AnimationPlayer"

var is_dragging_scroll = false
var drag_start_y = 0.0
var scroll_start_y = 0.0
var active_scroll = null

var is_dragging_panel = false
var panel_drag_start_y = 0.0
var panel_start_pos_y = 0.0

func _input(event):
	var card_section = $CollectionPanel/CardSection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if card_section.get_global_rect().has_point(event.global_position):
					active_scroll = card_section
				elif deck_zone.get_global_rect().has_point(event.global_position):
					active_scroll = deck_zone
				else:
					active_scroll = null
				if active_scroll:
					is_dragging_scroll = true
					drag_start_y = event.global_position.y
					scroll_start_y = active_scroll.scroll_vertical
			else:
				is_dragging_scroll = false
				active_scroll = null
	
	if event is InputEventMouseMotion and is_dragging_scroll and active_scroll:
		var delta = drag_start_y - event.global_position.y
		active_scroll.scroll_vertical = scroll_start_y + delta
		
	# Drag del CollectionPanel
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and drag_bar.get_global_rect().has_point(event.global_position):
			is_dragging_panel = true
			panel_drag_start_y = event.global_position.y
			panel_start_pos_y = collection_panel.position.y
		elif not event.pressed and is_dragging_panel:
			is_dragging_panel = false
			collection_expanded = collection_panel.position.y < (PANEL_Y_EXPANDED + PANEL_Y_COLLAPSED) / 2.0
			
	if event is InputEventMouseMotion and is_dragging_panel:
		var delta = event.global_position.y - panel_drag_start_y
		var new_y = clamp(panel_start_pos_y + delta, PANEL_Y_EXPANDED, PANEL_Y_COLLAPSED)
		collection_panel.position.y = new_y


func _ready():
	deck_builder = get_parent()
	
	await get_tree().process_frame
	var card_section = $CollectionPanel/CardSection
	card_section.size = Vector2(985, 1200)
	card_section.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_section.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	deck_zone.size = Vector2(1219, 987)
	deck_zone.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_zone.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	deck_grid.custom_minimum_size.x = 1219
	deck_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Oculta scrollbars
	card_section.get_v_scroll_bar().modulate = Color(0, 0, 0, 0)

	card_grid.custom_minimum_size.x = 985
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Señales FilterBar
	tropas_button.pressed.connect(func(): set_filter("Tropa"))
	tropas_button.pressed.connect(func(): collection_panel.visible = true)
	trucos_button.pressed.connect(func(): set_filter("Truco"))
	trucos_button.pressed.connect(func(): collection_panel.visible = true)
	entornos_button.pressed.connect(func(): set_filter("Entorno"))
	entornos_button.pressed.connect(func(): collection_panel.visible = true)
	supports_button.pressed.connect(func(): set_filter("Support"))
	supports_button.pressed.connect(func(): collection_panel.visible = true)
	mazo_button.pressed.connect(func(): set_filter("Mazo"))
	mazo_button.pressed.connect(func(): collection_panel.visible = false)
	
	# Señales CollectionPanel
	#drag_bar.pressed.connect(toggle_collection)
	search_button.pressed.connect(toggle_search)
	search_bar.visible = false
	search_bar.text_changed.connect(_on_search_changed)
	
	
	
	# Señales CardPreview
	close_button.pressed.connect(func(): card_preview.visible = false)
	add_button.pressed.connect(_on_add_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	
	# Señal nombre mazo
	deck_name_edit.text_changed.connect(_on_deck_name_changed)
	
	# CollectionPanel empieza colapsado
	collection_panel.position.y = PANEL_Y_COLLAPSED
	card_preview.visible = false
	
	#cambiar personaje
	personaje_button.pressed.connect(_on_change_character_pressed)
	
func _on_change_character_pressed():
	var db = get_parent()
	var panel_personaje = db.panel_personaje
	
	panel_personaje.show_confirm_dialog(
		"¿Cambiar personaje? \n \n Esto limpiará las cartas del mazo actual.",
		func():
			animacion.play("Transicion")
			animacion_timer.start()
			await animacion_timer.timeout
			# Elimina el deck actual completamente
			db.delete_deck(db.current_deck_name)
			panel_personaje.selected_character = ""
			panel_personaje.current_deck_name = ""  # ← resetea para que no detecte cambio
			db.current_deck_name = "" # ← resetea para que cree deck nuevo
			db.show_panel(panel_personaje)
	)
	

func setup(character_name: String, deck_name: String):
	var char_data = CharacterDatabase.Characters[character_name]
	var clases = char_data["clases"]
	
	# Íconos de clases
	var clase_logos = CharacterDatabase.ClaseLogos
	if clases.size() >= 1 and clases[0] in clase_logos:
		clase_icon1.texture = load(clase_logos[clases[0]])
	if clases.size() >= 2 and clases[1] in clase_logos:
		clase_icon2.texture = load(clase_logos[clases[1]])
	
	# Imagen personaje
	if "carta" in char_data:
		personaje_button.texture_normal = load(char_data["logo"])
		personaje_button.ignore_texture_size = true
		personaje_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	# Nombre del mazo
	deck_name_edit.text = deck_name
	
	# Cartas disponibles para este personaje
	available_cards = deck_builder.get_cards_for_character(character_name)
	
	populate_collection(available_cards)
	refresh_filter_counts()
	refresh_deck_zone()
	set_filter("Tropa")

# ── FILTROS ───────────────────────────────────────

func set_filter(tipo: String):
	active_filter = tipo
	
	# Resetea color de todos los botones
	var filter_buttons = {
		"Tropa": tropas_button,
		"Truco": trucos_button,
		"Entorno": entornos_button,
		"Support": supports_button,
		"Mazo": mazo_button
	}
	for key in filter_buttons:
		filter_buttons[key].add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Resalta el activo en amarillo
	filter_buttons[tipo].add_theme_color_override("font_color", Color(0.889, 0.801, 0.0, 1.0))
	
	refresh_deck_zone()
	# Filtra también la colección
	_apply_collection_filter(tipo)
	
func _apply_collection_filter(tipo: String):
	if tipo == "Mazo":
		populate_collection(available_cards)
		return
	
	var filtered = []
	for card_name in available_cards:
		var card_data = CardDatabase.Cards.get(card_name, null)
		if card_data == null or card_data.size() < 3:
			continue
		var card_tipo = card_data[2]
		var match_filter = false
		if tipo == "Tropa" and card_tipo == "Tropa":
			match_filter = true
		elif tipo == "Truco" and "Truco" in card_tipo:
			match_filter = true
		elif tipo == "Entorno" and card_tipo == "Entorno":
			match_filter = true
		elif tipo == "Support" and "Support" in card_tipo:
			match_filter = true
		if match_filter:
			filtered.append(card_name)
	
	populate_collection(filtered)

func refresh_filter_counts():
	var deck_name = deck_builder.current_deck_name
	if deck_name == "":
		return
	var cards = deck_builder.all_decks[deck_name]["cards"]
	var counts = {"Tropa": 0, "Truco": 0, "Entorno": 0, "Support": 0}
	for card_name in cards:
		var card_data = CardDatabase.Cards.get(card_name, null)
		if card_data == null or card_data.size() < 3:
			continue
		var tipo = card_data[2]
		if tipo == "Tropa":
			counts["Tropa"] += 1
		elif "Truco" in tipo:
			counts["Truco"] += 1
		elif tipo == "Entorno":
			counts["Entorno"] += 1
		elif "Support" in tipo:
			counts["Support"] += 1
	
	tropas_button.text = "TROPAS\n%d" % counts["Tropa"]
	trucos_button.text = "TRUCOS\n%d" % counts["Truco"]
	entornos_button.text = "ENTORNOS\n%d" % counts["Entorno"]
	supports_button.text = "SUPPORTS\n%d" % counts["Support"]
	mazo_button.text = "MAZO\n%d" % cards.size()
	
	if deck_builder.is_deck_valid(deck_builder.current_deck_name):
		validate_button.text = "✓"
		validate_button.modulate = Color(0.2, 0.9, 0.2)
	else:
		validate_button.text = "✗"
		validate_button.modulate = Color(0.9, 0.2, 0.2)

# ── DECK ZONE ─────────────────────────────────────

func refresh_deck_zone():
	for child in deck_grid.get_children():
		child.queue_free()
	
	var deck_name = deck_builder.current_deck_name
	if deck_name == "":
		return
	
	var cards = deck_builder.all_decks[deck_name]["cards"]
	
	# Agrupa cartas únicas con su conteo
	var card_counts = {}
	for card_name in cards:
		card_counts[card_name] = card_counts.get(card_name, 0) + 1
	
	for card_name in card_counts:
		var card_data = CardDatabase.Cards.get(card_name, null)
		if card_data == null or card_data.size() < 3:
			continue
		
		# Filtro activo
		if active_filter != "Mazo":
			var tipo = card_data[2]
			var match_filter = false
			if active_filter == "Tropa" and tipo == "Tropa":
				match_filter = true
			elif active_filter == "Truco" and "Truco" in tipo:
				match_filter = true
			elif active_filter == "Entorno" and tipo == "Entorno":
				match_filter = true
			elif active_filter == "Support" and "Support" in tipo:
				match_filter = true
			if not match_filter:
				continue
		
		var btn = _create_card_button(card_name, card_counts[card_name])
		deck_grid.add_child(btn)

# ── COLECCIÓN ─────────────────────────────────────

func populate_collection(cards: Array):
	for child in card_grid.get_children():
		child.queue_free()
	
	for card_name in cards:
		var count_in_deck = deck_builder.get_card_count_in_deck(deck_builder.current_deck_name, card_name)
		var available = 4 - count_in_deck  # cuántas puedo aún agregar
		var btn = _create_card_button(card_name, available)
		card_grid.add_child(btn)

func _create_card_button(card_name: String, count: int) -> Button:
	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(195, 220)
	$CollectionPanel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Forzar que no se expanda horizontalmente
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	var texture_rect = TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.custom_minimum_size = Vector2(195, 220)
	texture_rect.anchor_right = 1.0
	texture_rect.anchor_bottom = 1.0
	
	var card_image_path = "res://Cartas/%sCard.png" % card_name
	if ResourceLoader.exists(card_image_path):
		texture_rect.texture = load(card_image_path)
	
	btn.add_child(texture_rect)
	
	# Contador de copias (círculo abajo)
	if count >= 0:
		var circle = Panel.new()
		circle.custom_minimum_size = Vector2(50, 50)
		circle.position = Vector2(75, 190)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		style.corner_radius_top_left = 30
		style.corner_radius_top_right = 30
		style.corner_radius_bottom_left = 30
		style.corner_radius_bottom_right = 30
		circle.add_theme_stylebox_override("panel", style)
		
		var count_label = Label.new()
		count_label.text = str(count)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		count_label.add_theme_font_size_override("font_size", 20)
		count_label.add_theme_font_override("font", load("res://Cartas/OPTIIgnite.otf"))
		count_label.modulate = Color(0.0, 0.0, 0.0, 1.0) 
		
		circle.add_child(count_label)
		btn.add_child(circle)
		
	
	btn.pressed.connect(func(): show_card_preview(card_name))
	return btn

# ── CARD PREVIEW ──────────────────────────────────

func show_card_preview(card_name: String):
	selected_card_name = card_name
	var card_data = CardDatabase.Cards.get(card_name, null)
	
	var screen_size = get_viewport_rect().size
	background.scale = Vector2(25 ,50)
	background.color = Color(0.0, 0.0, 0.0, 0.737)  # Negro 70% opaco
	card_display.position = screen_size / 2
	
	label_ataque.position = screen_size / 2 + Vector2(-210, 250)
	label_vida.position = screen_size / 2 + Vector2(155, 250)
	label_habilidad.position = screen_size / 2 + Vector2(-270, 80)
	
	label_ataque.add_theme_font_size_override("normal_font_size", 85)
	label_vida.add_theme_font_size_override("normal_font_size", 85)
	label_habilidad.add_theme_font_size_override("normal_font_size", 120)
	
	if card_data == null:
		return
	
	card_preview.visible = true
	
	# Imagen
	var card_image_path = "res://Cartas/%sCard.png" % card_name
	if ResourceLoader.exists(card_image_path):
		card_display.texture = load(card_image_path)
		
	
	# Info
	label_ataque.text = "%s" % str(card_data[0]) if card_data[0] != null else ""
	label_vida.text = "%s" % str(card_data[1]) if card_data[1] != null else ""
	label_habilidad.text = str(card_data[3]) if card_data[3] != null else ""
	
	# Copias en mazo
	var count = deck_builder.get_card_count_in_deck(deck_builder.current_deck_name, card_name)
	copy_count.text = "DISPONIBLE \n %d / %d" % [count, 4]
	
	# Botones add/remove
	add_button.position = screen_size / 2 + Vector2(-398, 600)
	remove_button.position = screen_size / 2 + Vector2(0, 600)
	copy_count.position = screen_size / 2 + Vector2(-205, 450)
	close_button.position = screen_size / 2 + Vector2(-205, 750)
	add_button.disabled = not deck_builder.can_add_card(deck_builder.current_deck_name, card_name)
	remove_button.disabled = count == 0

func _on_add_pressed():
	deck_builder.add_card(deck_builder.current_deck_name, selected_card_name)
	refresh_filter_counts()
	refresh_deck_zone()
	_apply_collection_filter(active_filter)
	show_card_preview(selected_card_name)  # refresca conteo

func _on_remove_pressed():
	deck_builder.remove_card(deck_builder.current_deck_name, selected_card_name)
	refresh_filter_counts()
	refresh_deck_zone()
	_apply_collection_filter(active_filter)
	show_card_preview(selected_card_name)  # refresca conteo

# ── COLLECTION PANEL DRAG ─────────────────────────
#
#func toggle_collection():
	#collection_expanded = not collection_expanded
	#var target_y = PANEL_Y_EXPANDED if collection_expanded else PANEL_Y_COLLAPSED
	#var tween = create_tween()
	#tween.tween_property(collection_panel, "position:y", target_y, 0.3).set_ease(Tween.EASE_OUT)
	#drag_bar.text = "▼ Colección de cartas" if collection_expanded else "▲ Colección de cartas"

# ── BÚSQUEDA ──────────────────────────────────────

func toggle_search():
	search_bar.visible = not search_bar.visible
	if search_bar.visible:
		search_bar.grab_focus()
		$CollectionPanel/ColeccionLabel.visible = false
	else:
		$CollectionPanel/ColeccionLabel.visible = true
		search_bar.text = ""
		populate_collection(available_cards)

func _on_search_changed(query: String):
	if query.strip_edges() == "":
		populate_collection(available_cards)
		return
	
	var filtered = []
	for card_name in available_cards:
		var card_data = CardDatabase.Cards.get(card_name, null)
		if card_data == null:
			continue
		
		# Busca por nombre
		if query.to_lower() in card_name.to_lower():
			filtered.append(card_name)
			continue
		
		# Busca por costo
		if card_data.size() > 5 and str(card_data[5]) == query:
			filtered.append(card_name)
			continue
		
		# Busca por clase
		if card_data.size() > 6 and query.to_lower() in str(card_data[6]).to_lower():
			filtered.append(card_name)
			continue
		
		# Busca por subclase
		if card_data.size() > 7:
			for subclass in card_data[7]:
				if query.to_lower() in str(subclass).to_lower():
					filtered.append(card_name)
					break
	
	populate_collection(filtered)

# ── NOMBRE MAZO ───────────────────────────────────

func _on_deck_name_changed(new_name: String):
	var old_name = deck_builder.current_deck_name
	if new_name.strip_edges() != "" and new_name != old_name:
		if deck_builder.rename_deck(old_name, new_name):
			print("Mazo renombrado: ", new_name)

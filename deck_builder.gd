extends Node2D

const DECK_MAX_SIZE = 40
const MAX_COPIES_PER_CARD = 4
const SAVE_PATH = "user://decks.json"

var all_decks = {}  # {"Nuevo mazo 1": {character, cards[]}, ...}
var current_deck_name = ""
var CharacterDatabase = preload("res://Scripts/CharacterDatabase.gd")
var CardDatabase = preload("res://Scripts/CardDatabase.gd")
var deck_to_edit = ""
# Referencias a paneles
@onready var animacion = $AnimationPlayer
@onready var animacion_timer = $PanelPersonaje/CharacterPreview/AnimacionTimer
@onready var panel_personaje = $PanelPersonaje
@onready var panel_editor = $PanelEditor

# ── INICIO ────────────────────────────────────────

func _ready():
	load_all()
	if Global.deck_to_edit != "":
		current_deck_name = Global.deck_to_edit
		Global.deck_to_edit = ""
		show_panel(panel_editor)
		setup_editor()
	else:
		show_panel(panel_personaje)

# ── NAVEGACIÓN DE PANELES ─────────────────────────

func show_panel(panel):
	panel_personaje.visible = false
	panel_editor.visible = false
	panel.visible = true

func setup_editor():
	var character_name = panel_personaje.selected_character
	
	if character_name == "" and current_deck_name != "":
		character_name = all_decks[current_deck_name].get("character", "")
		panel_personaje.selected_character = character_name
	
	if character_name == "":
		print("Error: no hay personaje seleccionado")
		return
	
	panel_editor.setup(character_name, current_deck_name)



# ── CRUD ──────────────────────────────────────────

func create_deck(character_name, custom_name = ""):
	var name = custom_name if custom_name != "" else _generate_name()
	all_decks[name] = {
		"character": character_name,
		"cards": [],
		"created_at": Time.get_unix_time_from_system()
	}
	current_deck_name = name
	save_all()
	return name

func update_deck(deck_name, new_cards):
	if deck_name in all_decks:
		all_decks[deck_name]["cards"] = new_cards
		save_all()

func rename_deck(old_name, new_name):
	if old_name in all_decks and new_name not in all_decks:
		all_decks[new_name] = all_decks[old_name]
		all_decks.erase(old_name)
		if current_deck_name == old_name:
			current_deck_name = new_name
		save_all()
		return true
	return false

func delete_deck(deck_name):
	if deck_name in all_decks:
		all_decks.erase(deck_name)
		if current_deck_name == deck_name:
			current_deck_name = ""
		save_all()

func get_deck(deck_name):
	if deck_name in all_decks:
		return all_decks[deck_name]
	return null

func get_all_deck_names():
	return all_decks.keys()

# ── CARTAS ────────────────────────────────────────

func can_add_card(deck_name, card_name):
	if deck_name not in all_decks:
		return false
	var cards = all_decks[deck_name]["cards"]
	if cards.size() >= DECK_MAX_SIZE:
		return false
	if cards.count(card_name) >= MAX_COPIES_PER_CARD:
		return false
	return true

func add_card(deck_name, card_name):
	if can_add_card(deck_name, card_name):
		all_decks[deck_name]["cards"].append(card_name)
		save_all()
		return true
	return false

func remove_card(deck_name, card_name):
	if deck_name in all_decks:
		var cards = all_decks[deck_name]["cards"]
		if card_name in cards:
			cards.erase(card_name)
			save_all()
			return true
	return false

# ── GUARDADO ──────────────────────────────────────

func save_all():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(all_decks))
		file.close()

func load_all():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var result = JSON.parse_string(content)
		if result:
			all_decks = result

# ── UTILIDADES ────────────────────────────────────

func _generate_name():
	var index = 1
	while ("Nuevo mazo %d" % index) in all_decks:
		index += 1
	return "Nuevo mazo %d" % index

func get_cards_for_character(character_name):
	var character = CharacterDatabase.Characters[character_name]
	var available_cards = []
	var card_db = preload("res://Scripts/CardDatabase.gd")
	for card_name in card_db.Cards:
		
		var card_data = card_db.Cards[card_name]
		# Blindaje: verifica que la carta tenga índice [6] (clase)
		if card_data.size() <= 6:
			continue
		# Excluye cartas únicas (índice [8] == true)
		if card_data.size() > 8 and card_data[8] == true:
			continue
		var card_class = card_data[6]
		if card_class in character["clases"]:
			available_cards.append(card_name)
		
		#var card_class = card_db.Cards[card_name][6]
		#if card_class in character["clases"]:
			#available_cards.append(card_name)
	return available_cards
	
	

func get_card_count_in_deck(deck_name, card_name):
	if deck_name in all_decks:
		return all_decks[deck_name]["cards"].count(card_name)
	return 0
	
	
# validaciones: -------------

func is_deck_valid(deck_name):
	if deck_name not in all_decks:
		return false
	var cards = all_decks[deck_name]["cards"]
	if cards.size() != DECK_MAX_SIZE:
		return false
	# Verifica copias máximas
	var card_counts = {}
	for card in cards:
		card_counts[card] = card_counts.get(card, 0) + 1
		if card_counts[card] > MAX_COPIES_PER_CARD:
			return false
	return true

func is_deck_draft(deck_name):
	return not is_deck_valid(deck_name)

func change_character(deck_name, new_character):
	if deck_name in all_decks:
		all_decks[deck_name]["character"] = new_character
		all_decks[deck_name]["cards"] = []  # Limpia cartas
		save_all()
		return true
	return false

func get_selected_deck():
	return all_decks.get("_selected", "")

func select_deck(deck_name):
	if deck_name in all_decks and is_deck_valid(deck_name):
		all_decks["_selected"] = deck_name
		save_all()
		return true
	return false


func _on_button_pressed() -> void:
	if current_deck_name == "" or not panel_editor.visible:
		# Está en PanelPersonaje, sale directo
		animacion.play("Transicion")
		animacion_timer.start()
		await animacion_timer.timeout
		get_tree().change_scene_to_file("res://Scenes/DeckSelector.tscn")
		return
	
	if is_deck_valid(current_deck_name):
		save_all()
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	else:
		show_exit_dialog()

func show_exit_dialog():
	var dialog = $ConfirmDialog
	var screen_size = get_viewport_rect().size
	dialog.get_node("Background").scale = Vector2(25 ,50)
	dialog.get_node("Background").color = Color(0.0, 0.0, 0.0, 0.737) 
	dialog.visible = true
	
	dialog.get_node("Control/Message").text = "El mazo aún no está completo y no cumple con los requisitos para ser jugado.\n\n ¿Guardar como borrador?"
	
	var confirm_btn = dialog.get_node("Control/ConfirmarButton")
	var cancel_btn = dialog.get_node("Control/CancelarButton")
	
	# Desconectar señales previas
	for c in confirm_btn.pressed.get_connections():
		confirm_btn.pressed.disconnect(c.callable)
	for c in cancel_btn.pressed.get_connections():
		cancel_btn.pressed.disconnect(c.callable)
	
	confirm_btn.pressed.connect(_on_exit_confirm)
	cancel_btn.pressed.connect(_on_exit_cancel)

func _on_exit_confirm():
	save_all()
	get_tree().change_scene_to_file("res://Scenes/DeckSelector.tscn")

func _on_exit_cancel():
	$ConfirmDialog.visible = false

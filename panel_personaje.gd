extends Node2D

var selected_bando = ""
var selected_character = ""
var current_deck_name = ""
var CharacterDatabase
var DeckBuilder
var pending_action = null
@onready var animacion = $"../AnimationPlayer"
@onready var animacion_timer = $CharacterPreview/AnimacionTimer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	CharacterDatabase = preload("res://Scripts/CharacterDatabase.gd")
	DeckBuilder = preload("res://Scripts/deck_builder.gd")
	populate_characters("Villano")
	# Conectar botones fijos UNA sola vez
	$CharacterPreview/ConfirmarButton.pressed.connect(confirm_character)
	$CharacterPreview/CancelarButton.pressed.connect(func(): $CharacterPreview.visible = false)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_heroe_pressed() -> void:
	$Heroe.disabled = true
	$"../Fondo".texture = preload("res://UI/Mazos/HeroeFondo.png")
	$Superior/Sprite2D.texture = preload("res://UI/Mazos/HeroeSuperior.png")
	$"../ConfirmDialog/Control/FondoCartas".texture = preload("res://UI/Mazos/WarningHeroe.png")
	$"../PanelEditor/CollectionPanel/FondoCartas".texture = preload("res://UI/Mazos/GridCartasHeroe.png")
	$"../PanelEditor/Fondo".texture = preload("res://UI/Mazos/FondoDeckHeroe.png")
	$Villano.disabled = false
	on_bando_selected("Heroe")
	


func _on_villano_pressed() -> void:
	$Villano.disabled = true
	$"../Fondo".texture = preload("res://UI/Mazos/VillanoFondo.png")
	$Superior/Sprite2D.texture = preload("res://UI/Mazos/VillanoSuperior.png")
	$"../ConfirmDialog/Control/FondoCartas".texture = preload("res://UI/Mazos/WarningVillano.png")
	$"../PanelEditor/CollectionPanel/FondoCartas".texture = preload("res://UI/Mazos/GridCartasVillano.png")
	$"../PanelEditor/Fondo".texture = preload("res://UI/Mazos/FondoDeckVillano.png")
	$Heroe.disabled = false
	on_bando_selected("Villano")
	
func on_bando_selected(bando):
	selected_bando = bando
	populate_characters(bando)
	
	
func populate_characters(bando):
	var container = $PersonajeContainer/ColorRect/PersonajeContainer
	
	# Limpia personajes anteriores
	for child in container.get_children():
		child.queue_free()
	
	# Obtiene personajes del bando
	var characters = CharacterDatabase.get_characters_by_bando(bando)
	
	for char_name in characters:
		var char_data = CharacterDatabase.Characters[char_name]
		var is_unlocked = CharacterDatabase.is_unlocked(char_name)
		
		# Crea botón con imagen del personaje
		var button = Button.new()
		button.custom_minimum_size = Vector2(412, 267)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var texture = TextureRect.new()
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.custom_minimum_size = Vector2(267,267)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.2, 0.2, 0.502, 0.0)  # Color con transparencia
		button.add_theme_stylebox_override("normal", stylebox)
		button.add_theme_stylebox_override("hover", stylebox)
		button.add_theme_stylebox_override("pressed", stylebox)
		button.add_theme_stylebox_override("disabled", stylebox)
		
		texture.position = Vector2(206, 133.5)
		texture.size = Vector2(267,267)  # ← Agrega esto
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		if is_unlocked:
			# Imagen normal
			texture.texture = load(char_data["logo"])
			
			texture.modulate = Color(1, 1, 1, 1)
			button.pressed.connect(func(): show_character_preview(char_name))
		else:
			# Imagen bloqueada con tono oscuro
			texture.texture = load(char_data["logoBloqueado"])
			button.disabled = true  # ← No se puede presionar
		
		
		
		# Nombre del personaje
		#var label = Label.new()
		#label.text = char_name
		#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(texture)
		#vbox.add_child(label)
		button.add_child(vbox)
		
		# Al presionar muestra preview del personaje
		
		container.add_child(button)



func show_character_preview(char_name):
	
	
	selected_character = char_name
	
	var char_data = CharacterDatabase.Characters[char_name]
	var preview = $CharacterPreview
	
	preview.visible = true
	
	# Imagen y nombre
	var screen_size = get_viewport_rect().size
	preview.get_node("Background").scale = Vector2(25 ,50)
	preview.get_node("Background").color = Color(0.0, 0.0, 0.0, 0.737)
	preview.get_node("CharImage").scale = Vector2(0.6,0.6)
	preview.get_node("CharImage").position = screen_size / 2
	preview.get_node("CharImage").texture = load(char_data["carta"])
	
	# Limpia cartas únicas anteriores
	var container2 = $CharacterPreview/UniqueCardsContainer
	var unique_container = $CharacterPreview/UniqueCardsContainer/UniqueContainer
	
	container2.position = screen_size / 2 + Vector2(-328,215)
	container2.scale = Vector2(0.8,0.8)
	for child in unique_container.get_children():
		child.queue_free()
	
	# Muestra cartas únicas
	for card_name in char_data["cartas_unicas"]:
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(414, 155.5)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var texture = TextureRect.new()
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.custom_minimum_size = Vector2(414,155.5)
		texture.position = Vector2(414, 155.5)
		texture.size = Vector2(267,267)  # ← Agrega esto
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		
		var card_image_path = "res://Cartas/%sCard.png" % card_name
		texture.texture = load(card_image_path)
		
		# Al presionar muestra preview de la carta única
		button.pressed.connect(func(): show_unique_card_preview(card_name))
		unique_container.add_child(button)
	
	# Conecta botones de confirmación
	preview.get_node("Seleccionar").position = screen_size / 2 + Vector2(-335, 550)
	preview.get_node("ConfirmarButton").position = screen_size / 2 + Vector2(-398, 700)
	preview.get_node("CancelarButton").position = screen_size / 2 + Vector2(0, 700)
	

func show_unique_card_preview(card_name):
	var preview = $CardUniquePreview
	preview.visible = true
	
	var card_image_path = "res://Cartas/%sCard.png" % card_name
	var screen_size = get_viewport_rect().size
	preview.get_node("Background").scale = Vector2(25 ,50)
	preview.get_node("Background").color = Color(0.0, 0.0, 0.0, 0.737)
	preview.get_node("CardImage").scale = Vector2(0.6,0.6)
	preview.get_node("CardImage").position = screen_size / 2
	
	if ResourceLoader.exists(card_image_path):
		preview.get_node("CardImage").texture = load(card_image_path)
		
	preview.get_node("CerrarButton").position = screen_size / 2 + Vector2(-208, 700)
	preview.get_node("CerrarButton").pressed.connect(func(): preview.visible = false)

func confirm_character():
	var deck_builder = get_parent()
	# Fix bug señales múltiples: desconectar antes de reconectar
	var confirm_btn = $CharacterPreview/ConfirmarButton
	if confirm_btn.pressed.is_connected(confirm_character):
		confirm_btn.pressed.disconnect(confirm_character)
	
	confirm_btn.pressed.connect(confirm_character)
	# Si ya hay un mazo en edición verifica si necesita confirmación
	if current_deck_name != "" and deck_builder.all_decks[current_deck_name]["character"] != selected_character:
		show_confirm_dialog(
			"¿Deseas cambiar personaje? \n \n Esto limpiará las cartas del mazo actual.",
			func():
				animacion.play("Transicion")
				animacion_timer.start()
				await animacion_timer.timeout
				deck_builder.change_character(current_deck_name, selected_character)
				deck_builder.show_panel(deck_builder.panel_editor)
				deck_builder.setup_editor()
		)
		
	else:
		if current_deck_name == "":
			current_deck_name = deck_builder.create_deck(selected_character)
		animacion.play("Transicion")
		animacion_timer.start()
		await animacion_timer.timeout
		
		deck_builder.show_panel(deck_builder.panel_editor)
		deck_builder.setup_editor()
		
	
	$CharacterPreview.visible = false 
	
	


func show_confirm_dialog(message, action):
	pending_action = action
	var dialog = $"../ConfirmDialog"
	var screen_size = get_viewport_rect().size
	dialog.get_node("Background").scale = Vector2(25 ,50)
	dialog.get_node("Background").color = Color(0.0, 0.0, 0.0, 0.737)
	dialog.visible = true
	var confirm_btn = dialog.get_node("Control/ConfirmarButton")
	var cancel_btn = dialog.get_node("Control/CancelarButton")
	dialog.get_node("Control/Titulo").text = "AVISO" 
	dialog.get_node("Control/Message").text = message
	
	
	# Desconectar señales previas antes de reconectar
	if confirm_btn.pressed.get_connections().size() > 0:
		for c in confirm_btn.pressed.get_connections():
			confirm_btn.pressed.disconnect(c.callable)
	if cancel_btn.pressed.get_connections().size() > 0:
		for c in cancel_btn.pressed.get_connections():
			cancel_btn.pressed.disconnect(c.callable)
	
	confirm_btn.pressed.connect(func():
		dialog.visible = false
		if pending_action:
			pending_action.call()
			pending_action = null
	)
	cancel_btn.pressed.connect(func():
		dialog.visible = false
		pending_action = null
	)

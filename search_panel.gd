extends Node2D

var card_manager_reference
var card_scenes = []
var deck_reference
@onready var background = $Background      # ColorRect negro transparente
@onready var card_container = $ScrollContainer/CardContainer
signal card_selected
var card_database_reference


func _ready():
	deck_reference = $"../../Deck"
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	card_manager_reference = $"../../Card Manager"
	visible = false
	
	#var screen_size = get_viewport_rect().size
	#background.scale = Vector2(25 ,50)
	#background.color = Color(0.0, 0.0, 0.0, 0.737)  # Negro 70% opaco
	var screen_size = get_viewport_rect().size
	# Configura el fondo
	# Igual que card_preview
	$Background.visible = true
	$Background.position = Vector2(0, 0)
	$Background.size = screen_size
	$Background.color = Color(0.0, 0.0, 0.0, 0.698)
	
	
	
	
	# Titulo centrado arriba
	$Title.position = Vector2(80, 150)
	$Title.text = "Selecciona una carta"
	
	# Configurar scroll horizontal
	# Configurar scroll horizontal
	$ScrollContainer.position = Vector2(0, screen_size.y / 2 - 150)
	$ScrollContainer.size = Vector2(screen_size.x, 300)
	$ScrollContainer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	$ScrollContainer.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	# El CardContainer no necesita posicion, el HBoxContainer se posiciona solo
	$ScrollContainer/CardContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Boton abajo
	$CancelButton.position = Vector2(screen_size.x / 2 - 50, screen_size.y - 250)
	$CancelButton.text = "Cancelar"
	$CancelButton.pressed.connect(_on_cancel)

func start_search(filter_type):
	var searchable_cards = []
	for card_name in deck_reference.player_deck:
		var card_type = deck_reference.card_database_reference.Cards[card_name][2]
		if card_type == filter_type or filter_type == "":
			searchable_cards.append(card_name)
	
	populate(searchable_cards)
	visible = true

func populate(card_names):
	for child in card_container.get_children():
		child.queue_free()
	
	for card_name in card_names:
		# Contenedor clickeable
		var container = SubViewportContainer.new()
		container.custom_minimum_size = Vector2(300, 520)
		container.stretch = true
		
		var viewport = SubViewport.new()
		viewport.size = Vector2(300, 520)
		viewport.transparent_bg = true
		
		# Instanciar la carta real
		var card_scene = preload("res://Scenes/card.tscn").instantiate()
		var card_image_path = str("res://Cartas/" + card_name + "Card.png")
		card_scene.get_node("AnimationPlayer").play("card_flip")
		card_scene.get_node("CardImage").texture = load(card_image_path)
		card_scene.position = Vector2(150, 260) # centrada en el viewport
		card_scene.scale = Vector2(2.5, 2.5)
		
		card_scene.card_type = card_database_reference.Cards[card_name][2]
		card_scene.Ataque = card_database_reference.Cards[card_name][0]
		card_scene.Costo = card_database_reference.Cards[card_name][5]
		
		if card_scene.card_type == "Tropa":
			if card_scene.Ataque == 0:
				card_scene.get_node("Ataque").visible= false
			else:
				card_scene.get_node("Ataque").text = str(card_scene.Ataque)
			
			card_scene.Vida = card_database_reference.Cards[card_name][1]
			
			card_scene.get_node("Vida").text = str(card_scene.Vida)
			card_scene.get_node("Habilidad").text = str(card_database_reference.Cards[card_name][3])
			card_scene.get_node("Costo").text = str(card_scene.Costo)
		else:
			card_scene.get_node("Ataque").visible= false
			card_scene.get_node("Vida").visible= false
			var new_card_ability_script_path = card_database_reference.Cards[card_name][4]
			if new_card_ability_script_path:
				card_scene.Habilidad_script = load(new_card_ability_script_path).new()
			card_scene.Habilidad = card_database_reference.Cards[card_name][3]
			card_scene.get_node("Costo").text = str(card_scene.Costo)
			card_scene.get_node("Habilidad").text = str(card_database_reference.Cards[card_name][3])
		
		
		
		
		
		
		
		
		
		
		
		
		viewport.add_child(card_scene)
		container.add_child(viewport)
		
		# Click en el contenedor
		var btn = Button.new()
		btn.flat = true
		btn.size = container.custom_minimum_size
		btn.pressed.connect(func(): select_card(card_name))
		container.add_child(btn)
		
		card_container.add_child(container)

func select_card(card_name):
	deck_reference.player_deck.erase(card_name)
	deck_reference.draw_specific_card(card_name)
	visible = false
	emit_signal("card_selected")

func _on_cancel():
	visible = false
	emit_signal("card_selected")

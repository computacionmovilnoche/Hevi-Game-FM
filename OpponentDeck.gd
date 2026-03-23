extends Node2D


const card_scene_path = "res://Scenes/Enemycard.tscn"
const CARD_DRAW_SPEED = 0.2

const Starting_hand = 5


var opponent_deck = ["Hannah","Hannah","Cylindrus","Cylindrus","Aku","Aku","Drain","Pierre","OrdenSuprema"]
var card_database_reference


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	opponent_deck.shuffle() #cartas aleatorias
	$RichTextLabel.text = str(opponent_deck.size())
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	for i in range(Starting_hand):
		draw_card()





# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func draw_card():
	if opponent_deck.size() == 0:
		return
		
	var card_draw = opponent_deck[0]
	opponent_deck.erase(card_draw)
	
	if opponent_deck.size() == 0:
		
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
	
	$RichTextLabel.text = str(opponent_deck.size())
	var card_scene = preload(card_scene_path)
	var new_card = card_scene.instantiate() 
	
	var card_image_path = str("res://Cartas/" +card_draw+ "Card.png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	
	new_card.card_type = card_database_reference.Cards[card_draw][2]
	if new_card.card_type == "Tropa":
		new_card.Ataque = card_database_reference.Cards[card_draw][0]
		new_card.get_node("Ataque").text = str(new_card.Ataque )
		new_card.get_node("Vida").text = str(card_database_reference.Cards[card_draw][1])
	else:
		new_card.get_node("Ataque").visible= false
		new_card.get_node("Vida").visible= false


	$"../Card Manager".add_child(new_card)
	new_card.name = "card"
	new_card.scale = Vector2(1.5,1.5)
	$"../Card Manager".connect_card_signals(new_card)
	$"../EnemyHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	

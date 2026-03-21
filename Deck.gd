extends Node2D


const card_scene_path = "res://Scenes/card.tscn"
const CARD_DRAW_SPEED = 0.3

var player_deck = ["Hannah", "Hannah", "Hannah", "Hannah"]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$RichTextLabel.text = str(player_deck.size())
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func draw_card():
	var card_draw = player_deck[0]
	player_deck.erase(card_draw)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		$RichTextLabel.visible = false
	
	$RichTextLabel.text = str(player_deck.size())
	var card_scene = preload(card_scene_path)
	var new_card = card_scene.instantiate() 
	$"../Card Manager".add_child(new_card)
	new_card.name = "card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)

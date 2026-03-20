extends Node2D

const hand_count = 6
const card_scene_path = "res://Scenes/card.tscn"
const card_width = 150
const hand_y_position = 1696


var player_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = 540
	
	var card_scene = preload(card_scene_path)
	for i in range (hand_count):
		var new_card = card_scene.instantiate() 
		$"../Card Manager".add_child(new_card)
		new_card.name = "card"
		add_card_to_hand(new_card)

func add_card_to_hand(card):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions()
	else:
		animate_card_to_position(card,card.starting_position)

func update_hand_positions():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), hand_y_position)
		var card = player_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position)


func calculate_card_position(index):
	var total_width = (player_hand.size() -1) * card_width
	var x_offset = center_screen_x + index * card_width - total_width / 2
	return x_offset
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.1)



func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()

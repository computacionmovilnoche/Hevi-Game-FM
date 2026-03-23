extends Node2D



const card_width = 80
const hand_y_position = 0
const DEFAULT_CARD_MOVE_SPEED = 0.1


var opponent_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = 300
	
	

func add_card_to_hand(card, speed):
	if card not in opponent_hand:
		opponent_hand.insert(0, card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card,card.starting_position, DEFAULT_CARD_MOVE_SPEED)

func update_hand_positions(speed):
	for i in range(opponent_hand.size()):
		var new_position = Vector2(calculate_card_position(i), hand_y_position)
		var card = opponent_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position, speed)


func calculate_card_position(index):
	var total_width = (opponent_hand.size() -1) * card_width
	var x_offset = center_screen_x - index * card_width + total_width / 2
	return x_offset
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)



func remove_card_from_hand(card):
	if card in opponent_hand:
		opponent_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

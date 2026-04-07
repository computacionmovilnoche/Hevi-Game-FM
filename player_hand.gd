extends Node2D


const card_width = 150
const hand_y_position = 1696
const DEFAULT_CARD_MOVE_SPEED = 0.1
#control de velocidad en las cartas


var player_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = 540
	#esto pasa a DECK.GD para el robo de las cartas


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Solo inicia scroll si NO hay carta siendo arrastrada
			var card_manager = $"../../../Card Manager"
			if card_manager.card_being_dragged == null:
				var mouse_pos = get_global_mouse_position()
				# Verifica si el toque está en el área de la mano
				if _is_in_hand_area(mouse_pos):
					is_scrolling = true
					scroll_start_x = mouse_pos.x
					scroll_start_offset = hand_offset
		else:
			is_scrolling = false

	if event is InputEventMouseMotion and is_scrolling:
		var card_manager = $"../../../Card Manager"
		if card_manager.card_being_dragged == null:
			var delta_x = get_global_mouse_position().x - scroll_start_x
			if abs(delta_x) > SCROLL_THRESHOLD:
				hand_offset = scroll_start_offset + delta_x
				_clamp_offset()
				update_hand_positions(0.05)

func _is_in_hand_area(pos):
	var viewport_size = get_viewport_rect().size
	# El área de la mano es el tercio inferior de la pantalla
	return pos.y > viewport_size.y - 70

func _clamp_offset():
	# Limita el scroll para que las cartas no se vayan demasiado lejos
	var total_width = (player_hand.size() - 1) * card_width
	var max_offset = total_width / 2.0
	hand_offset = clamp(hand_offset, -max_offset, max_offset)

func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.append(card)
		update_hand_positions(speed)
		if card_manager_reference:
			card_manager_reference.update_hand_card_colors()
	else:
		animate_card_to_position(card, card.starting_position, DEFAULT_CARD_MOVE_SPEED)




func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions()
	else:
		animate_card_to_position(card,card.starting_position, DEFAULT_CARD_MOVE_SPEED)

func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), hand_y_position)
		var card = player_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position,speed)


func calculate_card_position(index):
	var total_width = (player_hand.size() -1) * card_width
	var x_offset = center_screen_x + index * card_width - total_width / 2
	return x_offset
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func animate_card_to_position(card, new_position, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, speed)



func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)

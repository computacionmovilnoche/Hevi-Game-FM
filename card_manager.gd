extends Node2D

#tdlpdj 3
const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_slot = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const CARD_BASE_SCALE = Vector2(2.8, 2.8)

var card_being_dragged
var screen_size
var is_hovering_o_card
var player_hand_reference

#guarda tamaño dela ventana asi la carta no se saldra  de la pantalla
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
    for child in get_children():
		if child.has_signal("hovered"):
			connect_card_signals(child)

#click derecho
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y))
	#click izquierdo

#se paso a deck.gd
	
# Called when the node enters the scene tree for the first time.
func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(2, 2)
	toggle_slots_visibility(true)
	

func finish_drag():
	if card_being_dragged:
		card_being_dragged.scale = CARD_BASE_SCALE
		var card_slot_found = raycast_check_for_card_slot()
		if card_slot_found and not card_slot_found.card_in_slot:
			card_being_dragged.position = card_slot_found.position
			player_hand_reference.remove_card_from_hand(card_being_dragged)
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			#indica cuando la carta se puso correctamente en un slot
			card_being_dragged.in_slot = true 
			card_being_dragged.scale = CARD_BASE_SCALE * 0.55
			card_slot_found.card_in_slot = true
		else:
			player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		toggle_slots_visibility(false)
		card_being_dragged = null
	
func toggle_slots_visibility(visible):
	for child in get_parent().get_children():
		if child.has_method("get") and child.get("card_in_slot") != null:
			if not child.card_in_slot:
				child.visible = visible

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	if !is_hovering_o_card:
		is_hovering_o_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_o_card = false

func highlight_card(card, hovered):
	if hovered:
		card.scale = CARD_BASE_SCALE * 1.1
		card.z_index = 2
	else:
		card.scale = CARD_BASE_SCALE
		card.z_index = 1
#parametros de busqueda

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_slot
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		
		return result[0].collider.get_parent()
	return null

func get_card_with_highest_z_index(cards):
	#esta funcion es para saber que carta esta siendo seleccionada, para pasar alfrente
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card

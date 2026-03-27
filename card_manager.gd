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

#deteccion de click o mantener presionado
const CLICK_THRESHOLD = 0.2
var click_timer = 0.0
var is_dragging = false
var card_preview_reference
#-------------

#verificador de cartas
var slots_tropa
var slots_entorno
var slots_linea
var slots_campo
#-----------


#guarda tamaño dela ventana asi la carta no se saldra  de la pantalla
func _ready() -> void:
	screen_size = get_viewport_rect().size
	slots_tropa = $"../SlotManager/SlotTropa"
	slots_entorno = $"../SlotManager/SlotEntorno"
	slots_linea = $"../SlotManager/SlotLinea"
	slots_campo = $"../SlotManager/SlotCampo"
	toggle_slots_visibility("", false)
	player_hand_reference = $"../PlayerHand"
	card_preview_reference = $"../CanvasLayer/CardPreview"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
    for child in get_children():
		if child.has_signal("hovered"):
			connect_card_signals(child)

#click derecho
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		click_timer += delta
		if click_timer > CLICK_THRESHOLD:
			is_dragging = true
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y))
	#click izquierdo

#se paso a deck.gd
	
# Called when the node enters the scene tree for the first time.
func start_drag(card):
	card_being_dragged = card
	click_timer = 0.0
	is_dragging = false
	card.scale = CARD_BASE_SCALE
	toggle_slots_visibility(card.card_type, true)
	

func finish_drag():
	if card_being_dragged:
		var battle_manager = $"../BattleManager"
		card_being_dragged.scale = CARD_BASE_SCALE
		var card_slot_found = raycast_check_for_card_slot()
		var card_type = card_being_dragged.card_type

		if battle_manager.is_opponent_turn:
			player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
			toggle_slots_visibility(card_type, false)
			card_being_dragged = null
			return

		if card_slot_found and not card_slot_found.card_in_slot and card_type in card_slot_found.card_slot_type:
			if (card_type == "Support_linea" or card_type == "Support_campo") and played_support_card:
				print("Ya jugaste un support este turno")
				player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
			else:
				card_being_dragged.position = card_slot_found.position
				player_hand_reference.remove_card_from_hand(card_being_dragged)
				card_being_dragged.get_node("Area2D").collision_layer = 8
				card_being_dragged.card_preview_reference = card_preview_reference
				#indica cuando la carta se puso correctamente en un slot
				
				card_being_dragged.in_slot = true 
				card_being_dragged.scale = CARD_BASE_SCALE * 0.7
				card_slot_found.card_in_slot = true
				card_being_dragged.card_preview_reference = card_preview_reference
				if card_type == "Support_linea" or card_type == "Support_campo":
					played_support_card = true
		else:
			player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		toggle_slots_visibility(card_type, false)
		card_being_dragged = null
	
func toggle_slots_visibility(card_type, show):
	if slots_tropa:
		slots_tropa.visible = false
		for slot in slots_tropa.get_children():
			if slot.has_node("Area2D"):
				slot.get_node("Area2D").set_collision_layer_value(2, false)
				slot.get_node("AnimationPlayer").play("slot_in")
	if slots_entorno:
		slots_entorno.visible = false
		for slot in slots_entorno.get_children():
			if slot.has_node("Area2D"):
				slot.get_node("Area2D").set_collision_layer_value(2, false)
				slot.get_node("AnimationPlayer").play("slot_in")
	if slots_linea:
		slots_linea.visible = false
		for slot in slots_linea.get_children():
			if slot.has_node("Area2D"):
				slot.get_node("Area2D").set_collision_layer_value(2, false)
				slot.get_node("AnimationPlayer").play("slot_in")
	if slots_campo:
		slots_campo.visible = false
		for slot in slots_campo.get_children():
			if slot.has_node("Area2D"):
				slot.get_node("Area2D").set_collision_layer_value(2, false)
				slot.get_node("AnimationPlayer").play("slot_in")
	if not show:
		return

	# Muestra solo el grupo correspondiente
	match card_type:
		"Tropa":
			if slots_tropa:
				slots_tropa.visible = true
				for slot in slots_tropa.get_children():
					slot.visible = true
					if slot.has_node("Area2D"):
						slot.get_node("Area2D").set_collision_layer_value(2, true)
		"Entorno":
			if slots_entorno:
				slots_entorno.visible = true
				for slot in slots_entorno.get_children():
					slot.visible = true
					if slot.has_node("Area2D"):
						slot.get_node("Area2D").set_collision_layer_value(2, true)
		"Truco_linea", "Support_linea":
			if slots_linea:
				slots_linea.visible = true
				for slot in slots_linea.get_children():
					slot.visible = true
					if slot.has_node("Area2D"):
						slot.get_node("Area2D").set_collision_layer_value(2, true)
		"Truco_campo", "Support_campo":
			if slots_campo:
				slots_campo.visible = true
				for slot in slots_campo.get_children():
					slot.visible = true
					if slot.has_node("Area2D"):
						slot.get_node("Area2D").set_collision_layer_value(2, true)

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_left_click_released():
	if card_being_dragged:
		if not is_dragging:
			# Fue un click corto → mostrar preview
			toggle_slots_visibility(false)
			player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
			card_being_dragged.scale = CARD_BASE_SCALE
			card_preview_reference.show_preview(card_being_dragged)
			card_being_dragged = null
		else:
			finish_drag()

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
		for r in result:
			var parent = r.collider.get_parent()
			if parent.get("card_slot_type") != null:
				return parent
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

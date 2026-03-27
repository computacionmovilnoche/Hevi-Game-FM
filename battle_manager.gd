extends Node

var battle_timer

var empty_tropa_card_slot = []
var speed = 0.2

const BATTLE_POS_OFFSET =25


var ramdom_empty_tropa_card_slot = []


var opponent_card_on_battlefield = []
var player_cards_on_battlefield = []

var starting_health = 20

var player_health
var opponent_health

var is_opponent_turn = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

    player_health = starting_health
	$"../HealthManager/PlayerHealth".text = str(player_health)
	opponent_health = starting_health
	$"../HealthManager/OpponentHealth".text = str(opponent_health)
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot2")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot3")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot4")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot5")

func _on_fin_turno_pressed() -> void:
	opponent_turn()
	
	
	



func opponent_turn():

	is_opponent_turn = true
	
	var player_hand = $"../PlayerHand".player_hand
	for card in player_hand:
		card.modulate = Color(0.525, 0.525, 0.525, 1.0)

	$"../Fin turno".disabled = true
	$"../Fin turno".visible = false
	
	
	#SI NPUEDE ROBAR CARTAS esperar
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		#wait 1 second
		battle_timer.start()
		await battle_timer.timeout
	
	#si hay slots libres se juega una tropa
	if empty_tropa_card_slot.size() != 0:
		await try_play_card()
	
	#fase ded ataques
	
	if opponent_card_on_battlefield.size() != 0 or player_cards_on_battlefield.size() != 0:
		for lane in range(1, 6):
			var enemy_card = get_opponent_card_in_lane(lane)
			var player_card = get_player_card_in_lane(lane)

			if enemy_card != null and player_card != null:
			# Ambos tienen carta → se atacan mutuamente
				await attack(enemy_card, player_card, "Opponent")
			elif enemy_card != null:
				# Solo enemigo → ataque directo al jugador
				await direct_attack(enemy_card, "Opponent")
			elif player_card != null:
			# Solo jugador → ataque directo al oponente
				await direct_attack(player_card, "Player")
	
	
	#fin turno
	end_opponent_turn()
	
func get_opponent_card_in_lane(lane):
	for card in opponent_card_on_battlefield:
		if card.card_slot_card_is_in != null and card.card_slot_card_is_in.lane == lane:
			return card
	return null

func get_player_card_in_lane(lane):
	for card in player_cards_on_battlefield:
		if card.card_slot_card_is_in != null and card.card_slot_card_is_in.lane == lane:
			return card
	return null

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1206
	else:
		#si el jugador ataca
		new_pos_y = 530
	var new_pos = Vector2(attacking_card.position.x,new_pos_y)
	
	attacking_card.z_index = 5
	
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, 0.1)
	await wait(0.15)
	
	if attacker == "Opponent":
		#hacer daño al jugador
		player_health = max(0, player_health - attacking_card.Ataque)
		$"../HealthManager/PlayerHealth".text = str(player_health)
	else:
		#hacer daño a oponente
		opponent_health = max(0, opponent_health - attacking_card.Ataque)
		$"../HealthManager/OpponentHealth".text = str(opponent_health)

	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, 0.3)
	attacking_card.z_index = 0
	
	await wait(0.5)
	
	

func attack(attacking_card, defending_card, attacker):
	
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var new_pos_enemy = Vector2(attacking_card.position.x, attacking_card.position.y + BATTLE_POS_OFFSET)
	#daño a las cartas
	#tropa enemiga -> carta propia
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, 0.1)
	await wait(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, 0.3)
	defending_card.Vida = max(0, defending_card.Vida - attacking_card.Ataque)
	defending_card.get_node("Vida").text = str(defending_card.Vida)
	attacking_card.z_index = 0
	await wait(0.4)
	defending_card.z_index = 5
	#carta propia -> carta enemiga
	var tween3 = get_tree().create_tween()
	tween3.tween_property(defending_card, "position", new_pos_enemy, 0.1)
	await wait(0.15)
	var tween4 = get_tree().create_tween()
	tween4.tween_property(defending_card, "position", defending_card.card_slot_card_is_in.position, 0.3)
	
	attacking_card.Vida = max(0, attacking_card.Vida - defending_card.Ataque)
	attacking_card.get_node("Vida").text = str(attacking_card.Vida)
	
	await wait(0.5)
	defending_card.z_index = 0
	var card_was_destroyed = false
	#Destruir carta cuando su vida sea 0
	if attacking_card.Vida == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroyed = true
	if defending_card.Vida == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			#si el atacante es el oponente destruye nuestra carta
			destroy_card(defending_card, "Player")
			card_was_destroyed = true
			
	

func destroy_card(card, card_owner):
	var new_pos
	if card_owner == "Player":
		new_pos = $"../PlayerDiscard".position
		card.scale = $"../PlayerDiscard".scale
		player_cards_on_battlefield.erase(card)
		if card.card_slot_card_is_in != null:
			card.card_slot_card_is_in.card_in_slot = false
			card.card_slot_card_is_in = null
	else:
		new_pos = $"../OpponentDiscard".position
		card.scale = $"../OpponentDiscard".scale
		opponent_card_on_battlefield.erase(card)
		if card.card_slot_card_is_in != null:
			card.card_slot_card_is_in.card_in_slot = false
			empty_tropa_card_slot.append(card.card_slot_card_is_in)
			card.card_slot_card_is_in = null
		
		
		
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, 0.1)
	await wait(0.15)
		
	
	
	

func try_play_card():
	var opponent_hand = $"../EnemyHand".opponent_hand
	
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
	#verificar si el slot de tropa esta vacio
	#si no hay espacio para poner tropas fin del turno
	
	#verificar si hay una carta tropa para jugar
	var tropa_cards = []
	for card in opponent_hand:
		if card.card_type == "Tropa":
			tropa_cards.append(card)
	
	#slot random vacio para jugar una carta
	ramdom_empty_tropa_card_slot = empty_tropa_card_slot[randi_range(0,empty_tropa_card_slot.size()-1)]
	empty_tropa_card_slot.erase(ramdom_empty_tropa_card_slot)
	
	#jugar carta con la mayor fuerza
	var card_with_highest_atk = tropa_cards[0]
	for card in tropa_cards:
		if card.Ataque > card_with_highest_atk.Ataque:
			card_with_highest_atk = card
			
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", ramdom_empty_tropa_card_slot.position, speed)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_atk, "scale", ramdom_empty_tropa_card_slot.scale * 1.7, speed)
	card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")
	
	$"../EnemyHand".remove_card_from_hand(card_with_highest_atk)
	card_with_highest_atk.card_slot_card_is_in = ramdom_empty_tropa_card_slot
	
	opponent_card_on_battlefield.append(card_with_highest_atk)
	
	#wait 1 second
	await wait(1)


func wait(wait_time):
	battle_timer.wait_time = wait_time 
	battle_timer.start()
	await battle_timer.timeout


func end_opponent_turn():
	#fin turno
	is_opponent_turn = false
	var player_hand = $"../PlayerHand".player_hand
	for card in player_hand:
		card.modulate = Color(1, 1, 1, 1)

	#reseteo robo de carta
	$"../Deck".reset_draw()
	$"../Card Manager".reset_played_support_card()
	$"../Fin turno".visible = true
	$"../Fin turno".disabled = false

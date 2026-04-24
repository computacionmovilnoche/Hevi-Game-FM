extends Node

var battle_timer
const BATTLE_POS_OFFSET =25

var empty_tropa_card_slot = []
var ramdom_empty_tropa_card_slot = []
var speed = 0.2

var opponent_card_on_battlefield = []
var player_cards_on_battlefield = []

var starting_health = 20

var player_health
var opponent_health

var player_coins
var opponent_coins
var starting_coin = 0

var is_opponent_turn = false
@onready var animacion = $"../ManagerCost/Animacion/AnimationCost"
# Called when the node enters the scene tree for the first time.

enum TurnPhase {COIN_FLIP, PLAYER_TROOPS, PLAYER_ALL, OPPONENT_TROOPS, OPPONENT_ALL, PLAYER_SPELLS, OPPONENT_SPELLS, COMBAT}


var current_phase = TurnPhase.COIN_FLIP
var player_goes_first = true




func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	player_health = starting_health
	$"../HealthManager/PlayerHealth".text = str(player_health)
	opponent_health = starting_health
	$"../HealthManager/OpponentHealth".text = str(opponent_health)
	await wait(1)
	var coin = starting_coin + 1
	$"../ManagerCost/Animacion/Costo".text = str(coin)
	$"../ManagerCost/Animacion/Costo2".text = str(coin)
	await wait(0.4)
	animacion.play("both_coins")
	await wait(0.5)
	starting_coin = starting_coin +1
	
	
	
	player_coins = starting_coin
	opponent_coins = starting_coin
	
	$"../ManagerCost/Costo".text = str(player_coins)
	$"../ManagerCost/Costo2".text = str(opponent_coins)
	await get_tree().process_frame
	await get_tree().process_frame
	
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot2")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot3")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot4")
	empty_tropa_card_slot.append($"../Slots oponente manager/slot enemigo tropa/EnemyCardSlot5")
	start_game()
	
	
func start_game():
	var coin_flip = $"../CanvasLayer/CoinFlip"
	coin_flip.coin_flip_finished.connect(_on_coin_flip_finished)
	coin_flip.start()
	
func _on_coin_flip_finished(goes_first):
	player_goes_first = goes_first
	
	if player_goes_first:
		set_phase(TurnPhase.PLAYER_TROOPS)
	else:
		set_phase(TurnPhase.OPPONENT_TROOPS)
	
	await $"../OpponentDeck".starting_hand()
	await $"../Deck".starting_hand()
	$"../Card Manager".update_hand_card_colors()

func set_phase(phase):
	current_phase = phase
	match phase:
		TurnPhase.PLAYER_TROOPS:
			
			is_opponent_turn = false
			$"../Fin turno".visible = true
			$"../Fin turno".disabled = false
			$"../Fin turno".text = "FIN FASE\nTROPAS"
			$"../Card Manager".allowed_card_types = ["Tropa"]
			_restore_player_hand()
			$"../Card Manager".update_hand_card_colors()

		TurnPhase.PLAYER_ALL:
			
			is_opponent_turn = false
			
			$"../Fin turno".visible = true
			$"../Fin turno".disabled = false
			$"../Fin turno".text = "FIN FASE"
			$"../Card Manager".allowed_card_types = ["Tropa", "Truco_linea", "Truco_campo", "Support_linea", "Support_campo", "Entorno"]
			_restore_player_hand()
			$"../Card Manager".update_hand_card_colors()

		TurnPhase.OPPONENT_TROOPS:
			await wait(1)
			is_opponent_turn = true
			_darken_player_hand()
			$"../Fin turno".visible = false
			
			
			if empty_tropa_card_slot.size() != 0:
				await try_play_card()
			else:
				await wait(1)
			set_phase(TurnPhase.PLAYER_ALL)

		TurnPhase.OPPONENT_ALL:
			is_opponent_turn = true
			_darken_player_hand()
			$"../Fin turno".visible = false
			if $"../OpponentDeck".opponent_deck.size() != 0:
				$"../OpponentDeck".draw_card()
				await wait(1)
			if empty_tropa_card_slot.size() != 0:
				await try_play_card()
			else:
				await wait(1)
			set_phase(TurnPhase.PLAYER_SPELLS)

		TurnPhase.PLAYER_SPELLS:
			
			is_opponent_turn = false
			
			$"../Fin turno".visible = true
			$"../Fin turno".disabled = false
			$"../Fin turno".text = "COMBATIR"
			$"../Card Manager".allowed_card_types = ["Truco_linea", "Truco_campo", "Support_linea", "Support_campo", "Entorno"]
			_restore_player_hand()
			$"../Card Manager".update_hand_card_colors()

		TurnPhase.OPPONENT_SPELLS:
			is_opponent_turn = true
			_darken_player_hand()
			$"../Fin turno".visible = false
			await wait(1)
			await try_play_spells()
			await wait(0.5)
			set_phase(TurnPhase.COMBAT)

		TurnPhase.COMBAT:
			is_opponent_turn = true
			_darken_player_hand()
			
			$"../Fin turno".visible = false
			await battle_phase()
			end_full_turn()

func _on_fin_turno_pressed() -> void:
	match current_phase:
		TurnPhase.PLAYER_TROOPS:
			# Jugador va primero → sigue IA con todo
			set_phase(TurnPhase.OPPONENT_ALL)
		TurnPhase.PLAYER_ALL:
			# Jugador va segundo → después de jugar todo, IA hace trucos
			set_phase(TurnPhase.OPPONENT_SPELLS)
		TurnPhase.PLAYER_SPELLS:
			# Jugador va primero → trucos terminan, combate
			set_phase(TurnPhase.COMBAT)

func battle_phase():
	if opponent_card_on_battlefield.size() != 0 or player_cards_on_battlefield.size() != 0:
		for lane in range(1, 6):
			var enemy_card = get_opponent_card_in_lane(lane)
			var player_card = get_player_card_in_lane(lane)
			if enemy_card != null and player_card != null:
				await attack(enemy_card, player_card, "Opponent")
			elif enemy_card != null:
				await direct_attack(enemy_card, "Opponent")
			elif player_card != null:
				await direct_attack(player_card, "Player")

func try_play_spells():
	# IA intenta jugar trucos y soportes
	var opponent_hand = $"../EnemyHand".opponent_hand
	var spell_types = ["Truco_linea", "Truco_campo", "Support_linea", "Support_campo", "Entorno"]
	
	for card in opponent_hand.duplicate():
		if card.card_type in spell_types and card.Costo <= opponent_coins:
			# Por ahora la IA juega el primer truco que pueda pagar
			opponent_coins -= card.Costo
			$"../ManagerCost/Costo2".text = str(opponent_coins)
			$"../EnemyHand".remove_card_from_hand(card)
			await wait(1)
			break  # Solo juega un truco por turno por simplicidad

func end_full_turn():
	_darken_player_hand()
	is_opponent_turn = false
	
	
	starting_coin += 1
	player_coins = starting_coin
	opponent_coins = starting_coin
	
	$"../ManagerCost/Animacion/Costo".text = str(player_coins)
	$"../ManagerCost/Animacion/Costo2".text = str(opponent_coins)
	animacion.play("both_coins")
	await wait(0.5)
	$"../ManagerCost/Costo".text = str(player_coins)
	$"../ManagerCost/Costo2".text = str(opponent_coins)
	await wait(0.5)
	
	$"../Deck".reset_draw()
	$"../Card Manager".reset_played_support_card()
	
	if $"../Deck".player_deck.size() != 0:
		$"../Deck".draw_card()
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		await wait(1)
	
	if player_goes_first:
		_darken_player_hand()
		set_phase(TurnPhase.PLAYER_TROOPS)
	else:
		_darken_player_hand()
		set_phase(TurnPhase.OPPONENT_TROOPS)
	_darken_player_hand()
	
	#$"../Card Manager".update_hand_card_colors()

func _darken_player_hand():
	var player_hand = $"../Responsive/HBoxContainer/PlayerHand".player_hand
	for card in player_hand:
		card.modulate = Color(0.525, 0.525, 0.525, 1.0)

func _restore_player_hand():
	$"../Card Manager".update_hand_card_colors()




func opponent_turn():
	is_opponent_turn = true
	
	var player_hand = $"../Responsive/HBoxContainer/PlayerHand".player_hand
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
		new_pos_y = 1600
	else:
		#si el jugador ataca
		new_pos_y = 530
	var new_pos = Vector2(attacking_card.position.x,new_pos_y)
	
	attacking_card.z_index = 5
	if attacking_card.Ataque != 0:
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
	
	
	check_win_condition()
	
func check_win_condition():
	if player_health <= 0:
		end_game("Derrota")
	elif opponent_health <= 0:
		end_game("Victoria")

func end_game(result):
	# Deshabilita todo
	is_opponent_turn = true
	$"../Fin turno".visible = false
	$"../Fin turno".disabled = true
	$"../InputManager".inputs_disabled = true
	
	
	
	# Muestra el resultado
	$"../CanvasLayer/GameResult".visible = true
	
	# Configura el fondo
	# Igual que card_preview
	$"../CanvasLayer/GameResult/Background".visible = true
	$"../CanvasLayer/GameResult/Background".position = Vector2(0, 0)
	$"../CanvasLayer/GameResult/Background".size = Vector2(3000, 3000)
	$"../CanvasLayer/GameResult/Background".color = Color(0.0, 0.0, 0.0, 0.698)
	# Titulo centrado arriba
	$"../CanvasLayer/GameResult/Title".position = Vector2(80, 150)
	$"../CanvasLayer/GameResult/Title".text = ""
	$"../CanvasLayer/GameResult/Menu".visible = true
	if result == "Victoria":
		$"../CanvasLayer/GameResult/Title".text = "¡VICTORIA!"
		$"../CanvasLayer/GameResult/Title".modulate = Color(1, 0.84, 0, 1)  # Dorado
	else:
		$"../CanvasLayer/GameResult/Title".text = "DERROTA"
		$"../CanvasLayer/GameResult/Title".modulate = Color(1, 0.2, 0.2, 1)  # Rojo

func attack(attacking_card, defending_card, attacker):
	
	
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var new_pos_enemy = Vector2(attacking_card.position.x, attacking_card.position.y + BATTLE_POS_OFFSET)
	#daño a las cartas
	#tropa enemiga -> carta propia
	if attacking_card.Ataque != 0:
		attacking_card.z_index = 5
		var tween = get_tree().create_tween()
		tween.tween_property(attacking_card, "position", new_pos, 0.1)
		await wait(0.15)
		var tween2 = get_tree().create_tween()
		tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, 0.3)
		defending_card.Vida = max(0, defending_card.Vida - attacking_card.Ataque)
		defending_card.get_node("Vida").text = str(defending_card.Vida)
		attacking_card.z_index = 0
		await wait(0.4)
		
	#carta propia -> carta enemiga
	
	if defending_card.Ataque != 0:
		defending_card.z_index = 5
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
		wait(2)
		
		return
	#verificar si el slot de tropa esta vacio
	#si no hay espacio para poner tropas fin del turno
	
	#verificar si hay una carta tropa para jugar
	var tropa_cards = []
	for card in opponent_hand:
		if card.card_type == "Tropa":
			tropa_cards.append(card)
	
	# Filtra cartas que el oponente puede pagar
	var affordable_cards = []
	for card in tropa_cards:
		if card.Costo <= opponent_coins:  # ← Verifica si puede pagarla
			affordable_cards.append(card)

	# Si no puede pagar ninguna carta termina el turno
	if affordable_cards.size() == 0:
		return

	ramdom_empty_tropa_card_slot = empty_tropa_card_slot[randi_range(0, empty_tropa_card_slot.size()-1)]
	empty_tropa_card_slot.erase(ramdom_empty_tropa_card_slot)

	# Jugar carta con mayor ataque que pueda pagar
	var card_with_highest_atk = affordable_cards[0]
	for card in affordable_cards:
		if card.Ataque > card_with_highest_atk.Ataque:
			card_with_highest_atk = card

	# Descuenta el costo
	opponent_coins -= card_with_highest_atk.Costo
	$"../ManagerCost/Costo2".text = str(opponent_coins)
			
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
	$"../Card Manager".update_hand_card_colors()
	#fin turno
	is_opponent_turn = false
	var player_hand = $"../Responsive/HBoxContainer/PlayerHand".player_hand
	for card in player_hand:
		card.modulate = Color(0.525, 0.525, 0.525, 1.0)
	#reseteo robo de carta
	
	starting_coin = starting_coin +1 
	player_coins = starting_coin
	opponent_coins = starting_coin
	
	$"../ManagerCost/Animacion/Costo".text = str(player_coins)
	$"../ManagerCost/Animacion/Costo2".text = str(opponent_coins)
	
	animacion.play("both_coins")
	await wait(0.5)

	$"../ManagerCost/Costo".text = str(player_coins)
	$"../ManagerCost/Costo2".text = str(opponent_coins)
	await wait(0.5)
	$"../Deck".reset_draw()
	
	$"../Card Manager".reset_played_support_card()
	$"../Fin turno".visible = true
	$"../Fin turno".disabled = false
	
	
func enable_emd_turn_button(is_enable):
	if is_enable:
		var player_hand = $"../Responsive/HBoxContainer/PlayerHand".player_hand
		$"../Card Manager".update_hand_card_colors()
		$"../Fin turno".visible = true
		$"../Fin turno".disabled = false
		
		
	else:
		var player_hand = $"../Responsive/HBoxContainer/PlayerHand".player_hand
		
		for card in player_hand:
			card.modulate = Color(0.525, 0.525, 0.525, 1.0)
			
		$"../Card Manager".update_hand_card_colors()
		$"../Fin turno".visible = false
		$"../Fin turno".disabled = true
		


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

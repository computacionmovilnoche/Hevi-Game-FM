extends Node

var battle_timer

var empty_tropa_card_slot = []
var speed = 0.2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	$"../Fin turno".disabled = true
	$"../Fin turno".visible = false
	
	
	#SI NPUEDE ROBAR CARTAS esperar
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		#wait 1 second
		battle_timer.start()
		await battle_timer.timeout
	
	if empty_tropa_card_slot.size() == 0:
		end_opponent_turn()
		return
	
	#jugar una carta
	#se espera 1 segundo
	await try_play_card()
	
	
	#fin turno
	end_opponent_turn()
	

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
	var ramdom_empty_tropa_card_slot = empty_tropa_card_slot[randi_range(0,empty_tropa_card_slot.size()-1)]
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
	
	#wait 1 second
	battle_timer.start()
	await battle_timer.timeout



func end_opponent_turn():
	#fin turno
	#reseteo robo de carta
	$"../Deck".reset_draw()
	$"../Card Manager".reset_played_support_card()
	$"../Fin turno".visible = true
	$"../Fin turno".disabled = false
	

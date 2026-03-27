extends Node

const riel_damage = 3

func trigger_ability(battle_manager_reference, card_with_ability,input_manager_reference):
	input_manager_reference.inputs_disabled=true
	
	battle_manager_reference.enable_emd_turn_button(false)
	
	await battle_manager_reference.wait(1)
	var cards_to_destroy = []
	for card in battle_manager_reference.opponent_card_on_battlefield:
		card.Vida = max(0, card.Vida - riel_damage)
		card.get_node("Vida").text = str(card.Vida)
		if card.Vida == 0:
			cards_to_destroy.append(card)
	
	await battle_manager_reference.wait(1)
	
	if cards_to_destroy.size() > 0:
		for card in cards_to_destroy:
			battle_manager_reference.destroy_card(card, "Opponent")
			
	battle_manager_reference.destroy_card(card_with_ability, "Player")
	await battle_manager_reference.wait(1)
	battle_manager_reference.enable_emd_turn_button(true)
	input_manager_reference.inputs_disabled=false
	

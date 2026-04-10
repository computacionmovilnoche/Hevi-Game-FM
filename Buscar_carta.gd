# En el script de la carta que busca
extends Node

func trigger_ability(battle_manager_reference, card_with_ability, input_manager_reference):
	input_manager_reference.inputs_disabled = true
	battle_manager_reference.enable_emd_turn_button(false)
	
	var search_panel = battle_manager_reference.get_node("../CanvasLayer/SearchPanel")
	search_panel.start_search("") #vacio para buscar cualquier carta
	
	await search_panel.card_selected
	
	battle_manager_reference.destroy_card(card_with_ability, "Player")
	input_manager_reference.inputs_disabled = false
	battle_manager_reference.enable_emd_turn_button(true)

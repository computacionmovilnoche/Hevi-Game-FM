extends Node2D

var suelo = true
var card_in_slot = false
var card_slot_type = ["Tropa"]

func _ready() -> void:
	visible = false
	$Area2D.set_collision_layer_value(2, false)

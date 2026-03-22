extends Node2D

signal hovered
signal hovered_off

#para saber si se le esta haciendo CLICK
signal card_clicked
var card_preview_reference

var in_slot = false
#saber si una carta esta en un slot

var starting_position = 890

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#get_parent().connect_card_signals(self)
	pass
	


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and in_slot:
			card_preview_reference.show_preview(self)

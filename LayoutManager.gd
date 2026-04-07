extends Node

var screen_size: Vector2
var center_x: float
var center_y: float

# ── Zonas verticales ──────────────────────────────
var enemy_hp_y: float
var enemy_slots_y: float

var enemy_slots_col_y: float    # campo/linea/entorno enemigo — MÁS ABAJO
var player_slots_col_y: float   # campo/linea/entorno jugador — MÁS ABAJO


var deck_y: float
var player_slots_y: float
var deck_discard_y: float
var o_deck_discard_y: float
var o_deck_y: float
var end_turn_button_y: float
var player_hand_y: float

# ── Zonas horizontales ────────────────────────────
var enemy_hp_x: float        # derecha
var player_hp_x: float       # izquierda
var deck_x: float            # derecha
var o_deck_x: float
var discard_x: float         # izquierda
var end_turn_x: float        # derecha

var slot_positions: Array = []   # Vector2 por cada lane
var slot_scale: float            # escala uniforme para todos los slots

const LANE_COUNT = 5
const SLOT_ORIGINAL_WIDTH = 150.0
const SLOT_SCALE_FACTOR = 1.1
var tropa_slot_gap_x: float #aumenta en X el espacio de las tropas


func _ready() -> void:
	recalculate()

func recalculate() -> void:
	screen_size = get_viewport().get_visible_rect().size
	center_x    = screen_size.x * 0.5
	center_y    = screen_size.y * 0.5
	
	tropa_slot_gap_x = screen_size.x * 0.01
	  # 2% del ancho — ajusta este valor
	
	
	# Verticales — ajusta los % a tu gusto
	enemy_hp_y          = screen_size.y * 0.08
	enemy_slots_y       = screen_size.y * 0.255
	
	enemy_slots_col_y = screen_size.y * 0.45   # campo/linea/entorno enemigo — más abajo
	player_slots_y    = screen_size.y * 0.53   # tropas jugador — igual que antes
	player_slots_col_y = screen_size.y * 0.45  # campo/linea/entorno jugador — más abajo
	
	deck_y      = screen_size.y * 0.74 #deck
	o_deck_y    = screen_size.y * 0.2
	end_turn_button_y   = screen_size.y * 0.71 #boton fin turno
	player_hand_y       = screen_size.y * 0.87

	# Horizontales
	enemy_hp_x          = screen_size.x * 0.80
	player_hp_x         = screen_size.x * 0.20
	deck_x              = screen_size.x * 0.94 #deck
	o_deck_x              = screen_size.x * 0.94
	discard_x           = screen_size.x * 0.15
	end_turn_x          = screen_size.x * 0.72 #boton fin turno
	
	discard_x      = screen_size.x * 0.08   # izquierda
	deck_discard_y = screen_size.y * 0.75   # descarte jugador — abajo
	o_deck_discard_y = screen_size.y * 0.15 # descarte oponente — arriba
	
	# Slots: distribuye 5 lanes en el 90% central del ancho
	var usable_width = screen_size.x * 0.90
	var lane_width   = usable_width / LANE_COUNT
	var start_x      = screen_size.x * 0.05 + lane_width * 0.5

	slot_positions.clear()
	for i in range(LANE_COUNT):
		slot_positions.append(Vector2(start_x + lane_width * i, 0))
		# la Y se asigna según si es enemigo o jugador en cada manager

	# Escala: el slot debe caber en el ancho de cada lane
	slot_scale = lane_width / SLOT_ORIGINAL_WIDTH

extends Node

static var game_active: bool = false
static var is_paused: bool = false
static var mouse_sensitivity: float = 0.003
static var player_name: String = "Player"

static var successful_sales: int = 0
static var impostors_caught: int = 0
static var total_real_visitors: int = 0
static var phone_disabled: bool = false

static var active_house_items: Array = []
static var current_visitor_claim: Dictionary = {}

signal visitor_arrived(dialogue: String)
signal visitor_resolved()
signal game_over(reason: String)
signal game_started()

static func reset_state():
	game_active = false
	is_paused = false
	successful_sales = 0
	impostors_caught = 0
	total_real_visitors = 0
	phone_disabled = false
	active_house_items.clear()
	current_visitor_claim.clear()

extends Node

var player_name: String = "Player"
var mouse_sensitivity: float = 0.003

var is_paused: bool = false
var game_active: bool = false
var current_visitor_claim: Dictionary = {}
var active_house_items: Array[Dictionary] = []
var phone_disabled: bool = false

var total_real_visitors: int = 0
var successful_sales: int = 0
var impostors_caught: int = 0

signal game_started
signal game_over(reason: String)
signal game_won
signal visitor_arrived(dialogue: String)
signal visitor_resolved

func reset_state():
	game_active = false
	current_visitor_claim.clear()
	active_house_items.clear()
	phone_disabled = false
	total_real_visitors = 0
	successful_sales = 0
	impostors_caught = 0

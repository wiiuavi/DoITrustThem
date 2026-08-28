class_name GameManager
extends Node

static var instance: GameManager

@export var prop_slots_parent: Node3D
@export var image_slots_parent: Node3D
@export var total_item_count: int = 15
@export var visitor_interval_seconds: float = 15.0
@export var game_duration_seconds: float = 1200.0
@export var visitor_patience_seconds: float = 18.0

var elapsed_time: float = 0.0
var visitor_timer: float = 0.0
var patience_timer: float = 0.0
var is_visitor_waiting: bool = false

func _enter_tree():
	instance = self

func _ready():
	Global.reset_state()
	Global.game_started.connect(_on_game_started)

func _on_game_started():
	Global.game_active = true
	generate_house_environment()
	elapsed_time = 0.0
	visitor_timer = 4.0

func generate_house_environment():
	Global.active_house_items.clear()
	
	if not prop_slots_parent:
		prop_slots_parent = get_node_or_null("../PropSlots")
	if not image_slots_parent:
		image_slots_parent = get_node_or_null("../ImageSlots")

	var slots: Array[Node] = []

	if prop_slots_parent:
		for slot in prop_slots_parent.get_children():
			if slot.has_method("spawn_random_prop"):
				slots.append(slot)

	if image_slots_parent:
		for slot in image_slots_parent.get_children():
			if slot.has_method("spawn_random_prop"):
				slots.append(slot)

	for slot in slots:
		if slot.has_method("clear_slot"):
			slot.clear_slot()

	slots.shuffle()

	for slot in slots:
		if Global.active_house_items.size() >= total_item_count:
			break
		if slot.has_method("spawn_random_prop"):
			var item_data = slot.spawn_random_prop()
			if not item_data.is_empty():
				Global.active_house_items.append(item_data)

func _process(delta: float):
	if not Global.game_active or Global.is_paused:
		return

	elapsed_time += delta
	if elapsed_time >= game_duration_seconds:
		_win_game()
		return

	if not is_visitor_waiting:
		visitor_timer -= delta
		if visitor_timer <= 0:
			spawn_visitor()
	else:
		patience_timer -= delta
		if patience_timer <= 0:
			_handle_visitor_timeout()

func spawn_visitor():
	is_visitor_waiting = true
	patience_timer = visitor_patience_seconds
	var is_truthful = randf() > 0.5
	var claim_item_name = ""
	var claim_color = ""

	if is_truthful and Global.active_house_items.size() > 0:
		var real_item = Global.active_house_items.pick_random()
		claim_item_name = real_item["name"]
		claim_color = real_item["color"]
	else:
		var fake_categories = []
		var fake_colors = ["Red", "Purple", "Cyan", "Magenta", "Gold", "Blue", "Green", "Yellow", "Black"]
		
		var template_parent = get_node_or_null("../TemplateProps")
		if template_parent:
			for child in template_parent.get_children():
				fake_categories.append(child.name)
				
		var image_titles = []
		var dir = DirAccess.open("res://images")
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					if file_name.ends_with(".png"):
						image_titles.append(file_name.trim_suffix(".png"))
					elif file_name.ends_with(".png.import"):
						var t = file_name.trim_suffix(".png.import")
						if not image_titles.has(t):
							image_titles.append(t)
				file_name = dir.get_next()
				
		var all_options = fake_categories + image_titles
		if all_options.is_empty():
			all_options = ["Box", "Vase"]
			
		claim_item_name = all_options.pick_random()
		if claim_item_name in image_titles:
			claim_color = ""
		else:
			claim_color = fake_colors.pick_random()
		
		is_truthful = false
		for item in Global.active_house_items:
			if item["name"] == claim_item_name and item["color"] == claim_color:
				is_truthful = true
				break

	if is_truthful:
		Global.total_real_visitors += 1

	Global.current_visitor_claim = {
		"name": claim_item_name,
		"color": claim_color,
		"is_truthful": is_truthful
	}

	var dialogue = ""
	if claim_color != "":
		dialogue = "Knock Knock! Hi, I'm here to grab the " + claim_color + " " + claim_item_name + " I bought on eBay."
	else:
		dialogue = "Knock Knock! Can you let me in? I left my " + claim_item_name + " inside."

	Global.visitor_arrived.emit(dialogue)

static func handle_player_decision(opened_door: bool):
	if not instance or not instance.is_visitor_waiting:
		UIManager.show_subtitle("No one is currently at the door.", 2.0)
		return

	var is_truthful = Global.current_visitor_claim["is_truthful"]

	if opened_door:
		if is_truthful:
			Global.successful_sales += 1
			UIManager.show_subtitle("Visitor: Thanks for letting me grab it! Bye!", 4.0)
			
			var claim_name = Global.current_visitor_claim["name"]
			var claim_color = Global.current_visitor_claim["color"]
			
			for i in range(Global.active_house_items.size() - 1, -1, -1):
				var item = Global.active_house_items[i]
				if item["name"] == claim_name and item["color"] == claim_color:
					if is_instance_valid(item["node"]):
						item["node"].queue_free()
					Global.active_house_items.remove_at(i)
					break
					
			if Global.active_house_items.is_empty():
				instance._win_game()
				return
			else:
				instance._resolve_visitor()
		else:
			instance._trigger_game_over("Why did you trust me, " + Global.player_name)
	else:
		if not is_truthful:
			Global.impostors_caught += 1
			UIManager.show_subtitle("Security called! The imposter was escorted away.", 4.0)
			instance._resolve_visitor()
		else:
			Global.phone_disabled = true
			UIManager.show_subtitle("Security: Calling security for no reason will result in no further responses.", 5.0)
			instance._resolve_visitor()

func _handle_visitor_timeout():
	var is_truthful = Global.current_visitor_claim["is_truthful"]
	if is_truthful:
		UIManager.show_subtitle("Visitor: What a scam... (Leaves)", 4.0)
		_resolve_visitor()
	else:
		_trigger_game_over("Should've called for help, " + Global.player_name)

func _resolve_visitor():
	is_visitor_waiting = false
	visitor_timer = visitor_interval_seconds
	Global.visitor_resolved.emit()

func _trigger_game_over(fail_text: String):
	Global.game_active = false
	Global.game_over.emit(fail_text)

func _win_game():
	Global.game_active = false
	_trigger_game_over("All items collected! You win!")

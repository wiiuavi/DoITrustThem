class_name UIManager
extends CanvasLayer

static var instance: UIManager

@onready var reticle: ColorRect = $Reticle
@onready var subtitle_label: Label = $SubtitleLabel
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var visitor_box: PanelContainer = $VisitorDialogueBox
@onready var visitor_text: Label = $VisitorDialogueBox/VisitorText
@onready var red_overlay: ColorRect = $RedOverlay
@onready var game_over_reason_label: Label = $FadeReasonLabel

@onready var name_input: LineEdit = $MainMenu/VBoxContainer/NameLineEdit
@onready var sens_slider_main: HSlider = $MainMenu/VBoxContainer/SensSlider
@onready var sens_slider_pause: HSlider = $PauseMenu/VBoxContainer/SensSlider
@onready var stats_label: Label = $GameOverMenu/VBoxContainer/StatsLabel
@onready var game_over_title: Label = $GameOverMenu/VBoxContainer/TitleLabel

var subtitle_timer: float = 0.0
var game_over_fading: bool = false

func _enter_tree():
	instance = self

func _ready():
	main_menu.show()
	pause_menu.hide()
	game_over_menu.hide()
	visitor_box.hide()
	game_over_reason_label.hide()
	red_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	Global.visitor_arrived.connect(_on_visitor_arrived)
	Global.visitor_resolved.connect(_on_visitor_resolved)
	Global.game_over.connect(_on_game_over)

	sens_slider_main.value = Global.mouse_sensitivity
	sens_slider_pause.value = Global.mouse_sensitivity
	sens_slider_main.value_changed.connect(_on_sens_changed)
	sens_slider_pause.value_changed.connect(_on_sens_changed)

func _process(delta: float):
	if subtitle_timer > 0:
		subtitle_timer -= delta
		if subtitle_timer <= 0:
			subtitle_label.text = ""

	if game_over_fading:
		red_overlay.color.a = move_toward(red_overlay.color.a, 0.75, 0.4 * delta)
		if red_overlay.color.a >= 0.75 and not game_over_menu.visible:
			_show_game_over_panel()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and Global.game_active:
		toggle_pause()

func toggle_pause():
	Global.is_paused = not Global.is_paused
	pause_menu.visible = Global.is_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Global.is_paused else Input.MOUSE_MODE_CAPTURED

static func set_reticle_active(active: bool):
	if instance and instance.reticle:
		instance.reticle.color = Color.CYAN if active else Color.WHITE

static func show_subtitle(text: String, duration: float = 3.0):
	if instance:
		instance.subtitle_label.text = text
		instance.subtitle_timer = duration

func _on_sens_changed(val: float):
	Global.mouse_sensitivity = val
	sens_slider_main.value = val
	sens_slider_pause.value = val

func _on_start_button_pressed():
	Global.is_paused = false
	if pause_menu:
		pause_menu.hide()
	if name_input.text.strip_edges() != "":
		Global.player_name = name_input.text.strip_edges()
	main_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Global.game_started.emit()

func _on_resume_button_pressed():
	toggle_pause()

func _on_main_menu_button_pressed():
	Global.is_paused = false
	if pause_menu:
		pause_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_visitor_arrived(dialogue: String):
	visitor_text.text = dialogue
	visitor_box.show()

func _on_visitor_resolved():
	visitor_box.hide()

func _on_game_over(reason: String):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	subtitle_timer = 0
	subtitle_label.text = ""
	visitor_box.hide()
	game_over_reason_label.text = reason
	game_over_reason_label.show()
	
	if reason == "All items collected! You win!":
		red_overlay.color = Color(0, 0, 0, 0.75)
		_show_game_over_panel()
	else:
		game_over_fading = true

func _show_game_over_panel():
	game_over_reason_label.hide()
	if game_over_reason_label.text == "All items collected! You win!":
		game_over_title.text = "YOU WIN!"
	else:
		game_over_title.text = "GAME OVER"
	stats_label.text = "Sales Made: " + str(Global.successful_sales) + " / " + str(Global.total_real_visitors) + "\nImpostors Caught: " + str(Global.impostors_caught)
	game_over_menu.show()

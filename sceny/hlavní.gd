extends Node

#načtení překážek
var pařez_scene = preload("res://sceny/pařez.tscn")
var kus_dreva_scene = preload("res://sceny/kus_dřeva.tscn")
var kámen_scene = preload("res://sceny/kámen.tscn")
var pták_scene = preload("res://sceny/ptak.tscn")
var obstacle_types := [pařez_scene, kus_dreva_scene, kámen_scene]
var obstacles : Array
var ptak_heights := [350, 600]

const CYKL_START_POS := Vector2i(260, 768)
const CAM_START_POS := Vector2i(1408,768)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 20
var high_scores : Array = []
const SAVE_PATH = "user://highscore.save"
var speed : float
const START_SPEED : float = 1440.0
const MAX_SPEED: int = 5000.0
var SPEED_MODIFIER : int = 11000
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs

func _ready():
	screen_size = get_window().size
	ground_height = $Zem.get_node("Sprite2D").get_node("Sprite2D1").texture.get_height()
	process_mode = Node.PROCESS_MODE_ALWAYS
	$GameOver.get_node("Button").pressed.connect(restart_button_clicked)
	load_highscore()
	new_game()
	
func new_game():
	#vynulování proměnných 
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	$GameOver.get_node("NameInput").text = ""
	
	#smazání všech překážek po restarování
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	#reset uzlů
	$Cyklista.position = CYKL_START_POS
	$Cyklista.velocity = Vector2i(0, 0)
	$Camera2D.position= CAM_START_POS
	$Zem.position= Vector2i(0, 0)
	
	#reset hud a game over
	$Hud.get_node("StartLabel").show()
	$GameOver.hide()

#delta je ulynulý čas od předchozího snímku
func _physics_process(delta):
	if game_running:
		#zrychlení hry a úprava obtížnosti
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		
		adjust_dificulty()
		
		#generace prekazek
		generate_obs()
		
		#univezální pohyb 
		var movement = speed * delta
		
		#pohyb kamery a cyklisty
		$Cyklista.position.x += movement 
		$Camera2D.position.x += movement 
		
		#aktualizování skóre
		score += movement
		show_score()
		
		#aktualizování pozice na zemi
		if $Camera2D.position.x - $Zem.position.x > screen_size.x * 2: 
			$Zem.position.x += screen_size.x * 0.55
			
		#smazání překážek, které už nejsou vidět
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
		
	else:
		if Input.is_action_pressed("ui_accept") and not get_tree().paused:
			game_running = true
			$Hud.get_node("StartLabel").hide()
			
func generate_obs():	
	#generace překážek na zemi 
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(30, 50):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 1000 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 865  
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		#náhodné objevení ptáka
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2 ) == 0:
				obs = pták_scene.instantiate()
				var obs_x : int = screen_size.x + score + 1000
				var obs_y : int = ptak_heights[randi() % ptak_heights.size()] + 300
				add_obs(obs, obs_x, obs_y)
				

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs) 
	obstacles.append(obs)
	
func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)
	
func hit_obs(body):
	if body.name == "Cyklista":
		game_over()
		

func show_score():
	$Hud.get_node("ScoreLabel").text = "SCORE:" + str(score / SCORE_MODIFIER)

func adjust_dificulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY
		
func check_high_score():
	var current_display_score = int(score / SCORE_MODIFIER)
	var entered_name = $GameOver.get_node("NameInput").text
	if entered_name == "":
		entered_name = "Hráč"
		
	var current_date = Time.get_date_string_from_system()
	
	var new_entry = {
		"name": entered_name,
		"score": current_display_score,
		"date": current_date
	}
	
	high_scores.append(new_entry)

	high_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	
	save_highscore()
	update_highscore_label()

func save_highscore():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data = {
		"score": high_scores
	}
	var json_string = JSON.stringify(data, "\t") 
	file.store_string(json_string)

func load_highscore():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)

		var json_string = file.get_as_text()
		var data = JSON.parse_string(json_string)
		
		if data != null and typeof(data) == TYPE_DICTIONARY:
			high_scores = data.get("score", 0)
		else:
			high_scores = []
	else:
		high_scores = []

		
	update_highscore_label()

func update_highscore_label():
	if high_scores.size() > 0:
		var best_entry = high_scores[0]
		$Hud.get_node("HighScoreLabel").text = "REKORD: " + best_entry["name"] + " (" + str(best_entry["score"]) + ")"
	else:
		$Hud.get_node("HighScoreLabel").text = "REKORD: zatím nikdo"
func game_over():
	get_tree().paused = true
	game_running = false
	$GameOver.show()

func restart_button_clicked():
	check_high_score()

	new_game()

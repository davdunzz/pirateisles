extends Node2D

const SAVE_PATH := "user://pirate_isles.save"
const WORLD := Rect2(-900, -600, 1800, 1200)
const ISO_X := 0.86
const ISO_Y := 0.48

var state := "menu"
var player := Vector2(-600, 320)
var player_hp := 100.0
var coins := 180
var weapon_level := 1
var income_clock := 0.0
var message := ""
var message_time := 0.0
var selected_island := -1
var puzzle_step := 0
var boss_hp := 0.0
var boss_max_hp := 0.0
var attack_cooldown := 0.0
var boss_attack_clock := 0.0
var touch_move := Vector2.ZERO
var elapsed := 0.0

var islands := [
	{"name":"Isola Corallo", "pos":Vector2(-560,280), "size":105.0, "reward":120, "income":3, "color":Color("48c78e"), "conquered":false,
	 "riddles":[["Non ha voce, ma racconta ogni viaggio.",["La mappa","Il vento","La spada"],0],["Più ne togli, più diventa grande.",["Il tesoro","Una buca","La nave"],1]]},
	{"name":"Atollo delle Nebbie", "pos":Vector2(-180,-250), "size":130.0, "reward":210, "income":5, "color":Color("59b982"), "conquered":false,
	 "riddles":[["Corre senza gambe e non si ferma mai.",["Il mare","La sabbia","Il fuoco"],0],["Ha denti ma non può mordere.",["Il pettine","Lo squalo","La chiave"],0]]},
	{"name":"Rocca del Kraken", "pos":Vector2(170,230), "size":155.0, "reward":320, "income":8, "color":Color("67c587"), "conquered":false,
	 "riddles":[["Sono piena di buchi ma trattengo l'acqua.",["La vela","La spugna","La rete"],1],["Appartiene a te, ma gli altri lo usano più di te.",["Il tuo nome","Il tuo oro","Il timone"],0]]},
	{"name":"Isola Vulcano", "pos":Vector2(520,-180), "size":175.0, "reward":470, "income":12, "color":Color("a6a858"), "conquered":false,
	 "riddles":[["Nasce grande e muore piccola.",["Una candela","Una montagna","Un'onda"],0],["Sale sempre ma non scende mai.",["La marea","L'età","Il sole"],1]]},
	{"name":"Corona Nera", "pos":Vector2(650,330), "size":210.0, "reward":800, "income":20, "color":Color("8e795c"), "conquered":false,
	 "riddles":[["Se mi nomini, mi rompi.",["Il silenzio","Il vetro","L'incantesimo"],0],["Ha città senza case e mari senza acqua.",["Una mappa","Un sogno","Il cielo"],0]]}
]

func _ready() -> void:
	set_process(true)
	queue_redraw()

func iso(v: Vector2) -> Vector2:
	var c := get_viewport_rect().size * 0.5
	var camera := player if state == "world" else Vector2.ZERO
	var p := v - camera
	return c + Vector2((p.x - p.y) * ISO_X, (p.x + p.y) * ISO_Y)

func _process(delta: float) -> void:
	elapsed += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	message_time = maxf(0.0, message_time - delta)
	if state == "world":
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down") + touch_move
		if direction.length() > 1.0: direction = direction.normalized()
		player += direction * 220.0 * delta
		player.x = clampf(player.x, WORLD.position.x, WORLD.end.x)
		player.y = clampf(player.y, WORLD.position.y, WORLD.end.y)
		income_clock += delta
		if income_clock >= 15.0:
			income_clock = 0.0
			var gained := total_income()
			if gained > 0:
				coins += gained
				toast("Le tue isole producono +%d monete" % gained)
		if Input.is_action_just_pressed("interact"): try_enter_cave()
		if Input.is_action_just_pressed("shop"): state = "shop"
	elif state == "boss":
		boss_attack_clock += delta
		if Input.is_action_just_pressed("attack"): hit_boss()
		if boss_attack_clock >= 1.45:
			boss_attack_clock = 0.0
			player_hp -= 7.0 + selected_island * 2.5
			toast("Il guardiano ti colpisce!")
			if player_hp <= 0:
				player_hp = 100
				state = "world"
				player = islands[selected_island].pos + Vector2(0, islands[selected_island].size + 65)
				toast("Sei stato sconfitto. Migliora l'arma e riprova.")
	queue_redraw()

func try_enter_cave() -> void:
	for i in islands.size():
		var island: Dictionary = islands[i]
		if player.distance_to(island.pos) < island.size + 35:
			if island.conquered:
				toast("Quest'isola appartiene già alla tua ciurma.")
				return
			selected_island = i
			puzzle_step = 0
			state = "puzzle"
			return
	toast("Avvicinati all'ingresso luminoso di una grotta.")

func answer_puzzle(choice: int) -> void:
	var data: Array = islands[selected_island].riddles[puzzle_step]
	if choice == data[2]:
		puzzle_step += 1
		if puzzle_step >= 2:
			boss_max_hp = 85.0 + selected_island * 55.0
			boss_hp = boss_max_hp
			boss_attack_clock = 0.0
			state = "boss"
			toast("Gli enigmi sono risolti. Il guardiano si risveglia!")
	else:
		coins = maxi(0, coins - 15)
		state = "world"
		toast("Risposta errata: la grotta prende 15 monete.")

func hit_boss() -> void:
	if attack_cooldown > 0: return
	attack_cooldown = 0.38
	boss_hp -= 12.0 + weapon_level * 8.0
	if boss_hp <= 0:
		var island: Dictionary = islands[selected_island]
		islands[selected_island].conquered = true
		coins += island.reward
		player_hp = 100
		state = "world"
		player = island.pos
		toast("%s conquistata! +%d monete" % [island.name, island.reward])
		save_game()
		if conquered_count() == islands.size(): state = "victory"

func buy_weapon(level: int, price: int) -> void:
	if weapon_level >= level:
		toast("Possiedi già quest'arma.")
	elif coins < price:
		toast("Non hai abbastanza monete.")
	else:
		coins -= price
		weapon_level = level
		toast("Nuova arma equipaggiata!")
		save_game()

func total_income() -> int:
	var value := 0
	for island in islands:
		if island.conquered: value += island.income
	return value

func conquered_count() -> int:
	var value := 0
	for island in islands:
		if island.conquered: value += 1
	return value

func toast(text: String) -> void:
	message = text
	message_time = 3.2

func save_game() -> void:
	var flags := []
	for island in islands: flags.append(island.conquered)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"coins":coins,"weapon":weapon_level,"flags":flags,"x":player.x,"y":player.y}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		state = "world"
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		coins = int(data.get("coins", 180))
		weapon_level = int(data.get("weapon", 1))
		player = Vector2(float(data.get("x", -600)), float(data.get("y", 320)))
		var flags: Array = data.get("flags", [])
		for i in mini(flags.size(), islands.size()): islands[i].conquered = bool(flags[i])
	state = "world"

func new_game() -> void:
	coins = 180
	weapon_level = 1
	player = Vector2(-600,320)
	player_hp = 100
	for i in islands.size(): islands[i].conquered = false
	state = "world"
	save_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if state == "world": state = "pause_menu"
		elif state in ["shop","pause_menu"]: state = "world"
	if event is InputEventScreenTouch:
		if not event.pressed:
			touch_move = Vector2.ZERO
		elif state == "world" and event.position.x < 350:
			var center := Vector2(145, get_viewport_rect().size.y - 145)
			touch_move = (event.position - center).normalized()
		elif state == "world" and event.position.x > get_viewport_rect().size.x - 230:
			try_enter_cave()
		elif state == "boss": hit_boss()
	if event is InputEventScreenDrag and state == "world" and event.position.x < 350:
		var center := Vector2(145, get_viewport_rect().size.y - 145)
		touch_move = (event.position - center).normalized()

func _gui_click(pos: Vector2) -> void:
	var size := get_viewport_rect().size
	if state == "menu":
		if Rect2(size.x/2-150,390,300,58).has_point(pos): new_game()
		elif Rect2(size.x/2-150,462,300,58).has_point(pos): load_game()
		elif Rect2(size.x/2-150,534,300,58).has_point(pos): get_tree().quit()
	elif state == "puzzle":
		for i in 3:
			if Rect2(size.x/2-270,360+i*68,540,54).has_point(pos): answer_puzzle(i)
	elif state == "shop":
		if Rect2(size.x/2-270,300,540,64).has_point(pos): buy_weapon(2,250)
		elif Rect2(size.x/2-270,380,540,64).has_point(pos): buy_weapon(3,650)
		elif Rect2(size.x/2-110,500,220,54).has_point(pos): state = "world"
	elif state == "pause_menu":
		if Rect2(size.x/2-130,340,260,56).has_point(pos): state = "world"
		elif Rect2(size.x/2-130,410,260,56).has_point(pos): save_game(); state = "menu"
	elif state == "victory":
		if Rect2(size.x/2-130,510,260,58).has_point(pos): state = "menu"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_gui_click(event.position)
	if event is InputEventScreenTouch and event.pressed and state in ["menu","puzzle","shop","pause_menu","victory"]:
		_gui_click(event.position)

func panel(rect: Rect2, color := Color(0.035,0.075,0.12,0.94)) -> void:
	rounded_box(rect, color, Color(0.15,0.75,0.78,0.35), 2.0, 18.0)

func rounded_box(rect: Rect2, fill: Color, border: Color, width: float, radius: float) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(int(width))
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)

func label(text: String, pos: Vector2, font_size := 24, color := Color.WHITE, center := false) -> void:
	var font := ThemeDB.fallback_font
	var p := pos
	if center: p.x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2.0
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func button(rect: Rect2, text: String, accent := false) -> void:
	var fill := Color("147f88") if accent else Color(0.075,0.13,0.18,0.96)
	rounded_box(rect, fill, Color(0.2,0.85,0.85,0.55), 2, 14)
	label(text, Vector2(rect.get_center().x, rect.position.y + rect.size.y/2 + 8), 21, Color.WHITE, true)

func _draw() -> void:
	var size := get_viewport_rect().size
	# Deep ocean gradient-like bands and moving currents.
	draw_rect(Rect2(Vector2.ZERO,size), Color("071928"))
	for i in 12:
		var y := fmod(i*73.0 + elapsed*8.0, size.y+80.0)-40.0
		draw_line(Vector2(0,y),Vector2(size.x,y+110),Color(0.05,0.35,0.46,0.12),32)
	if state in ["world","pause_menu","shop"]: draw_world()
	if state == "menu": draw_menu()
	elif state == "puzzle": draw_puzzle()
	elif state == "boss": draw_boss()
	elif state == "shop": draw_shop()
	elif state == "pause_menu": draw_pause()
	elif state == "victory": draw_victory()
	if message_time > 0 and state != "menu":
		panel(Rect2(size.x/2-260,size.y-86,520,54),Color(0.02,0.08,0.11,0.96))
		label(message,Vector2(size.x/2,size.y-51),18,Color("d9ffff"),true)

func draw_menu() -> void:
	var size := get_viewport_rect().size
	# Logo compass.
	draw_circle(Vector2(size.x/2,178),92,Color(0.04,0.24,0.29,0.8))
	for i in 8:
		var a := i*TAU/8.0
		draw_line(Vector2(size.x/2,178)+Vector2.from_angle(a)*45,Vector2(size.x/2,178)+Vector2.from_angle(a)*82,Color("6ce5dd"),5)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x/2,92),Vector2(size.x/2-18,190),Vector2(size.x/2+18,190)]),Color("ffd166"))
	label("PIRATE ISLES",Vector2(size.x/2,305),48,Color("f4e9cf"),true)
	label("CROWN OF TIDES",Vector2(size.x/2,342),19,Color("63dbd5"),true)
	button(Rect2(size.x/2-150,390,300,58),"NUOVA PARTITA",true)
	button(Rect2(size.x/2-150,462,300,58),"CONTINUA")
	button(Rect2(size.x/2-150,534,300,58),"ESCI")
	label("Conquista le cinque isole e spezza la Corona Nera",Vector2(size.x/2,650),17,Color(0.7,0.78,0.8),true)

func draw_world() -> void:
	var size := get_viewport_rect().size
	for i in islands.size():
		var island: Dictionary = islands[i]
		var p := iso(island.pos)
		var r: float = island.size
		if p.x < -300 or p.x > size.x+300 or p.y < -200 or p.y > size.y+200: continue
		# Isometric land shadow, beach and center.
		draw_set_transform(p,0,Vector2(1.0,0.52))
		draw_circle(Vector2(10,22),r+10,Color(0.01,0.05,0.07,0.5))
		draw_circle(Vector2.ZERO,r+8,Color("d6c17a"))
		draw_circle(Vector2(0,-7),r,island.color.darkened(0.25) if island.conquered else island.color)
		for j in 7:
			var a := j*2.39 + i
			var q := Vector2.from_angle(a)*(r*0.55)
			draw_circle(q,10+fmod(j*7,13),Color(0.05,0.28,0.18,0.7))
		draw_set_transform(Vector2.ZERO)
		var cave := p + Vector2(0,-r*0.32)
		draw_circle(cave,18+sin(elapsed*3)*3,Color("ffd166") if not island.conquered else Color("54e0a5"))
		draw_circle(cave,10,Color("10151c"))
		label(island.name,p+Vector2(0,r*0.58+35),16,Color("efffff"),true)
		if island.conquered: label("CONQUISTATA • +%d/15s"%island.income,p+Vector2(0,r*0.58+57),13,Color("6ff0b4"),true)
	# Player ship/pirate marker centered because camera follows.
	var pp := iso(player)
	draw_circle(pp+Vector2(0,10),22,Color(0,0,0,0.35))
	draw_colored_polygon(PackedVector2Array([pp+Vector2(-22,8),pp+Vector2(22,8),pp+Vector2(13,22),pp+Vector2(-14,22)]),Color("78472b"))
	draw_line(pp+Vector2(0,8),pp+Vector2(0,-32),Color("e9d6a8"),4)
	draw_colored_polygon(PackedVector2Array([pp+Vector2(2,-30),pp+Vector2(24,-12),pp+Vector2(2,-7)]),Color("f0e4c5"))
	# HUD.
	panel(Rect2(24,22,330,86))
	label("☠  CAPITANO DELLE MAREE",Vector2(44,53),16,Color("6ce5dd"))
	label("%d monete"%coins,Vector2(44,85),24,Color("ffd166"))
	label("Isole %d/%d"%[conquered_count(),islands.size()],Vector2(205,84),19,Color.WHITE)
	panel(Rect2(size.x-292,22,268,86))
	label("Arma livello %d"%weapon_level,Vector2(size.x-270,55),18)
	label("Rendita +%d ogni 15s"%total_income(),Vector2(size.x-270,85),17,Color("6ff0b4"))
	label("WASD muovi  •  E grotta  •  B negozio",Vector2(26,size.y-20),15,Color(0.7,0.83,0.86))
	# Mobile controls.
	draw_circle(Vector2(145,size.y-145),72,Color(0.1,0.7,0.72,0.15))
	draw_circle(Vector2(145,size.y-145),32,Color(0.2,0.85,0.82,0.28))
	draw_circle(Vector2(size.x-112,size.y-138),58,Color(0.95,0.65,0.2,0.24))
	label("GROTTA",Vector2(size.x-112,size.y-132),14,Color("ffe4a1"),true)

func draw_puzzle() -> void:
	var size := get_viewport_rect().size
	panel(Rect2(size.x/2-340,145,680,430))
	label("SIGILLO DELLA GROTTA",Vector2(size.x/2,205),25,Color("63dbd5"),true)
	label("Enigma %d di 2"%(puzzle_step+1),Vector2(size.x/2,245),16,Color(0.65,0.75,0.78),true)
	var data: Array = islands[selected_island].riddles[puzzle_step]
	label(data[0],Vector2(size.x/2,310),23,Color("f4e9cf"),true)
	for i in 3: button(Rect2(size.x/2-270,360+i*68,540,54),data[1][i],i==0)

func draw_boss() -> void:
	var size := get_viewport_rect().size
	label("GUARDIANO DI %s"%islands[selected_island].name.to_upper(),Vector2(size.x/2,70),25,Color("ff8f70"),true)
	rounded_box(Rect2(size.x/2-260,95,520,25),Color("321b25"),Color("783648"),2,12)
	draw_rect(Rect2(size.x/2-252,103,504*maxf(0,boss_hp/boss_max_hp),9),Color("ff5c70"))
	var c := Vector2(size.x/2,size.y/2-10)
	for i in 10:
		var a := elapsed*(0.35+i*0.02)+i*TAU/10
		draw_circle(c+Vector2.from_angle(a)*150,12,Color(0.1,0.75,0.72,0.4))
	draw_circle(c,105,Color("421b3a"))
	draw_circle(c+Vector2(-36,-15),12,Color("ffd166"))
	draw_circle(c+Vector2(36,-15),12,Color("ffd166"))
	draw_arc(c,70,0.3,PI-0.3,24,Color("ff6b6b"),7)
	panel(Rect2(34,32,240,70))
	label("Vita %d/100"%int(player_hp),Vector2(55,62),19)
	draw_rect(Rect2(55,76,190*player_hp/100.0,8),Color("54e0a5"))
	button(Rect2(size.x/2-150,size.y-115,300,64),"ATTACCA  •  SPAZIO",true)

func draw_shop() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.03,0.05,0.68))
	panel(Rect2(size.x/2-340,170,680,400))
	label("EMPORIO DEL CORSARO",Vector2(size.x/2,225),30,Color("ffd166"),true)
	label("Il tuo oro: %d"%coins,Vector2(size.x/2,262),19,Color("f4e9cf"),true)
	button(Rect2(size.x/2-270,300,540,64),"Sciabola delle Onde • Livello 2 • 250")
	button(Rect2(size.x/2-270,380,540,64),"Lama del Kraken • Livello 3 • 650",true)
	button(Rect2(size.x/2-110,500,220,54),"TORNA AL MARE")

func draw_pause() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,0.58))
	panel(Rect2(size.x/2-220,235,440,270))
	label("PAUSA",Vector2(size.x/2,300),34,Color("f4e9cf"),true)
	button(Rect2(size.x/2-130,340,260,56),"CONTINUA",true)
	button(Rect2(size.x/2-130,410,260,56),"SALVA E MENU")

func draw_victory() -> void:
	var size := get_viewport_rect().size
	for i in 24:
		var p := Vector2(fmod(i*97.0,size.x),fmod(i*59.0+elapsed*30,size.y))
		draw_circle(p,5,Color("ffd166"))
	panel(Rect2(size.x/2-370,150,740,440))
	label("RE DEI CINQUE MARI",Vector2(size.x/2,245),43,Color("ffd166"),true)
	label("La Corona Nera è caduta.",Vector2(size.x/2,310),25,Color("f4e9cf"),true)
	label("Le isole hanno scelto un solo capitano: te.",Vector2(size.x/2,352),20,Color("bdeeee"),true)
	label("Hai completato la campagna di Pirate Isles.",Vector2(size.x/2,420),18,Color(0.7,0.8,0.82),true)
	button(Rect2(size.x/2-130,510,260,58),"MENU PRINCIPALE",true)

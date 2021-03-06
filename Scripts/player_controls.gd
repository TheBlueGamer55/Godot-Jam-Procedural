
extends KinematicBody2D

var vel = Vector2()

var gravity = 0.3
var moveSpeed = 3.0
var jumpSpeed = 7.0
var maxSpeedX = 6.0
var maxSpeedY = 6.0
var frictionX = 0.6
var knockbackX = 8
var knockbackY = 3
var onGround = false
var facingLeft = true

var teleportCoolingDown = false
var teleportTimer = 0
var maxTeleportTimer = 0.1 #teleport cooldown

var shootingCoolingDown = false
var shootingTimer = 0
var maxShootingTimer = 1 #shooting cooldown

var rockProjectileScene = load("res://Scenes/rock_projectile.scn")
var fireProjectileScene = load("res://Scenes/fire_projectile.scn")

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	
func _input(event):
	if(event.type == InputEvent.MOUSE_BUTTON):
		if(event.button_index == BUTTON_LEFT && event.pressed):
			if(!shootingCoolingDown):
				shootProjectile(event.pos)
				shootingCoolingDown = true
		elif(event.button_index == BUTTON_RIGHT && event.pressed):
			#if(!teleportCoolingDown):
				#teleport(event.pos)
			if(!shootingCoolingDown):
				shootFireProjectile(event.pos)
				shootingCoolingDown = true

func _fixed_process(delta):
	if(Input.is_action_pressed("UI_PAUSE")):
		if(!get_tree().is_paused()):
			var pauseMenu = get_parent().find_node("PauseMenuPopup")
			pauseMenu.toggle()
			get_tree().set_pause(true)
	
	#teleport cooldown check
	if(teleportCoolingDown):
		teleportTimer += delta
		if(teleportTimer >= maxTeleportTimer):
			teleportCoolingDown = false
			teleportTimer = 0
			
	#shooting cooldown check
	if(shootingCoolingDown):
		shootingTimer += delta
		if(shootingTimer >= maxShootingTimer):
			shootingCoolingDown = false
			shootingTimer = 0
	
	if(test_move(Vector2(0, 1))):
		onGround = true
	else:
		onGround = false
	
	#jump
	if(Input.is_key_pressed(KEY_SPACE) && onGround):
		vel.y = -jumpSpeed
		get_node("/root/sound_effects").play("jump1")
		
	if(Input.is_key_pressed(KEY_A)):
		vel.x = -moveSpeed
		facingLeft = true
	if(Input.is_key_pressed(KEY_D)):
		vel.x = moveSpeed
		facingLeft = false
	
	#limit falling speed
	if(vel.y > maxSpeedY):
		vel.y = maxSpeedY
	if(abs(vel.x) > maxSpeedX):
		vel.x = sign(vel.x) * abs(vel.x)
	
	updateSprite()
	frictionX()
	moveX()
	moveY()
	
	#gravity
	vel.y += gravity

func updateSprite():
	if(facingLeft && get_node("Sprite").is_flipped_h()):
		get_node("Sprite").set_flip_h(false)
		get_node("ParticlesLeft").set_emitting(true)
		get_node("ParticlesRight").set_emitting(false)
	elif(!facingLeft && !get_node("Sprite").is_flipped_h()):
		get_node("Sprite").set_flip_h(true)
		get_node("ParticlesLeft").set_emitting(false)
		get_node("ParticlesRight").set_emitting(true)
	
	var region = get_node("Sprite").get_region_rect()
	if(vel.x == 0 && region.pos.x == 0):
		get_node("Sprite").set_region_rect(Rect2(32, 0, 32, 32))
	elif(vel.x != 0 && region.pos.x == 32):
		get_node("Sprite").set_region_rect(Rect2(0, 0, 32, 32))

func shootProjectile(mousePos):
	get_node("/root/sound_effects").play("throw_rock")
	var cam = find_node("Camera2D")
	var w = get_viewport().get_rect().size.x
	var h = get_viewport().get_rect().size.y
	var cx = cam.get_camera_pos().x - (w / 2)
	var cy = cam.get_camera_pos().y - (h / 2)
	var mx = cx + mousePos.x
	var my = cy + mousePos.y
	var angle = atan2(my - get_pos().y, mx - get_pos().x)
	var dir = Vector2(cos(angle), -sin(angle))
	var rock = rockProjectileScene.instance()
	#rock.set_pos(Vector2(get_pos().x, get_pos().y - 64))
	rock.set_pos(Vector2(get_pos().x + (dir.x*64), get_pos().y - (dir.y*64)))
	rock.setVelocity(dir.x*5, -dir.y*5)
	get_parent().add_child(rock)

func shootFireProjectile(mousePos):
	get_node("/root/sound_effects").play("throw_rock")
	var cam = find_node("Camera2D")
	var w = get_viewport().get_rect().size.x
	var h = get_viewport().get_rect().size.y
	var cx = cam.get_camera_pos().x - (w / 2)
	var cy = cam.get_camera_pos().y - (h / 2)
	var mx = cx + mousePos.x
	var my = cy + mousePos.y
	var angle = atan2(my - get_pos().y, mx - get_pos().x)
	var dir = Vector2(cos(angle), -sin(angle))
	var fire = fireProjectileScene.instance()
	#fire.set_pos(Vector2(get_pos().x, get_pos().y - 64))
	fire.set_pos(Vector2(get_pos().x + (dir.x*64), get_pos().y - (dir.y*64)))
	fire.setVelocity(dir.x*5, -dir.y*5)
	get_parent().add_child(fire)

func teleport(mousePos):
	var cam = find_node("Camera2D")
	var w = get_viewport().get_rect().size.x
	var h = get_viewport().get_rect().size.y
	var cx = cam.get_camera_pos().x - (w / 2)
	var cy = cam.get_camera_pos().y - (h / 2)
	var mx = cx + mousePos.x
	var my = cy + mousePos.y
	
	var terrain = get_tree().get_nodes_in_group("terrain_group")[0]
	var terrainPos = terrain.get_pos()
	var size = terrain.getTileSize()
	if(mx < terrainPos.x || mx > terrainPos.x + terrain.getWidth()*size):
		return
	if(my < terrainPos.y || my > terrainPos.y + terrain.getHeight()*size):
		return
	
	var prevPos = get_pos()
	set_pos(Vector2(mx, my))
	#if teleport unsuccessful, no cooldown
	if(is_colliding()):
		set_pos(prevPos)
		teleportCoolingDown = false
	else:
		teleportCoolingDown = true

func moveX():
	var currentVel = Vector2(vel.x, 0)
	move(currentVel)

func moveY():
	var currentVel = Vector2(0, vel.y)
	move(currentVel)

func frictionX():
	if(vel.x > 0):
		vel.x -= frictionX
		if(vel.x < 0):
			vel.x = 0

	if(vel.x < 0):
		vel.x += frictionX
		if(vel.x > 0):
			vel.x = 0

func knockback(dir):
	get_node("/root/sound_effects").play("hit1")
	var mx
	var my
	if(dir.x < 0):
		mx = -knockbackX
	elif(dir.x >= 0):
		mx = knockbackX
	if(dir.y > 0):
		my = knockbackY
	elif(dir.y <= 0):
		my = -knockbackY
	vel.x = mx
	vel.y = my

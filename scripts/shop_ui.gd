extends CanvasLayer

var time_left := 30.0
var points := 0
var active := false

@onready var timer_label = $VBoxContainer/TimerLabel
@onready var points_label = $VBoxContainer/PointsLabel
@onready var health_button = $VBoxContainer/UpgradeArtContainer/MaxHealthContainer/MaxHealthButton
@onready var damage_button = $VBoxContainer/UpgradeArtContainer/BulletDamageContainer/BulletDamageButton
@onready var fire_rate_button = $VBoxContainer/UpgradeArtContainer/FireRateContainer/FireRateButton
var custom_font = load("res://assets/fonts/press_start.ttf")

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/DoneButton.pressed.connect(_on_done_pressed)
	
	health_button.pressed.connect(_on_health_upgrade)
	damage_button.pressed.connect(_on_damage_upgrade)
	fire_rate_button.pressed.connect(_on_fire_rate_upgrade)

func open_shop():
	time_left = 30.0
	visible = true
	active = true
	get_tree().paused = true
	# Pause shop spawning when shop is open
	get_node("/root/Main/Grid").set_shop_paused(true)
	update_button_text() 
	update_points_display()


func update_button_text():
	health_button.text = "Health (Lv.%d)\nCost: %d" % [UpgradeManager.health_level, UpgradeManager.health_cost]
	damage_button.text = "Damage (Lv.%d)\nCost: %d" % [UpgradeManager.damage_level, UpgradeManager.damage_cost]
	fire_rate_button.text = "Fire Rate (Lv.%d)\nCost: %d" % [UpgradeManager.fire_rate_level, UpgradeManager.fire_rate_cost]


func _process(delta):
	if not active:
		return
	time_left -= delta
	timer_label.text = str(int(ceil(time_left)))
	timer_label.add_theme_font_override("font", custom_font)
		
	if time_left <= 0:
		close_shop()

func update_points_display():
	points_label.text = "Points: %d" % points

func close_shop():
	# Resume shop spawning when shop closes
	get_node("/root/Main/Grid").set_shop_paused(false)
	get_node("/root/Main/Grid").shop_paused = false
	active = false
	visible = false
	get_tree().paused = false

func _on_done_pressed():
	close_shop()



func _on_done_button_pressed() -> void:
	print("Done clicked")  # debug
	close_shop()


func _on_damage_upgrade():
	if points >= UpgradeManager.damage_cost:
		points -= UpgradeManager.damage_cost
		UpgradeManager.upgrade_damage()
		update_button_text()
		update_points_display()


func _on_fire_rate_upgrade():
	if points >= UpgradeManager.fire_rate_cost:
		points -= UpgradeManager.fire_rate_cost
		UpgradeManager.upgrade_fire_rate()
		update_button_text()
		update_points_display()


func _on_health_upgrade():
	if points >= UpgradeManager.health_cost:
		points -= UpgradeManager.health_cost
		UpgradeManager.upgrade_health()
		update_button_text()
		update_points_display()
		

func add_points(amount: int):
	points += amount
	update_points_display()

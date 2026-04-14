extends CanvasLayer

@export var player_path: NodePath
@export var boss_path: NodePath

@onready var health_label: Label = $PlayerHUD/VBoxContainer/Label
@onready var health_bar: ProgressBar = $PlayerHUD/VBoxContainer/ProgressBar

@onready var boss_health_label: Label = $BossHUD/VBoxContainer/Label
@onready var boss_health_bar: ProgressBar = $BossHUD/VBoxContainer/ProgressBar
@onready var boss_hud: CenterContainer = $BossHUD

var player
var boss

func _ready():
	player = get_node_or_null(player_path)
	if player:
		player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player.health, player.max_health)

	boss = get_node_or_null(boss_path)
	if boss:
		boss.health_changed.connect(_on_boss_health_changed)
		_on_boss_health_changed(boss.health, boss.max_health)
	else:
		boss_hud.visible = false

func _on_player_health_changed(current: int, maximum: int):
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [current, maximum]

func _on_boss_health_changed(current: int, maximum: int):
	boss_hud.visible = current > 0
	boss_health_bar.max_value = maximum
	boss_health_bar.value = current
	boss_health_label.text = "Boss HP: %d / %d" % [current, maximum]

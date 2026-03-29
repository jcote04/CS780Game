extends CanvasLayer

@export var player_path: NodePath

@onready var health_label: Label = $MarginContainer/VBoxContainer/Label
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar

var player

func _ready():
	player = get_node(player_path)
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health, player.max_health)

func _on_health_changed(current: int, maximum: int):
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "HP: %d / %d" % [current, maximum]

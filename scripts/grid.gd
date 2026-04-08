extends Node2D
@export var rows := 4
@export var cols := 4
@export var font_size := 32
@export var cell_size := Vector2(120, 120)
@export var cell_spacing := Vector2(20, 20)
@export var cell_chars := [
	"1","2","3","4",
	"Q","W","E","R",
	"A","S","D","F",
	"Z","X","C","V"
]
@export var quadrants = [
		[0,1,4,5],
		[2,3,6,7],
		[8,9,12,13],
		[10,11,14,15],
		[0,1,2,3,4,7,8,11,12,13,14,15],
		[0,1,2,3],
		[0,4,8,12],
		[3,7,11,15],
		[12,13,14,15]
	]
	
var cells := []
var disabled_cells := {}
var font = load("res://assets/fonts/press_start.ttf")

func _ready():
	position = get_viewport().get_visible_rect().size / 2
	var total_width = cols * cell_size.x + (cols - 1) * cell_spacing.x
	var total_height = rows * cell_size.y + (rows - 1) * cell_spacing.y
	var start_x = -total_width / 2
	var start_y = -total_height / 2
	var index = 0
	for y in range(rows):
		for x in range(cols):
			var cell = Node2D.new()
			cells.append(cell)
			add_child(cell)
			cell.position = Vector2(
				start_x + x * (cell_size.x + cell_spacing.x) + cell_size.x / 2,
				start_y + y * (cell_size.y + cell_spacing.y) + cell_size.y / 2
			)

			# Sprite
			var sprite = Sprite2D.new()
			sprite.texture = preload("res://assets/sprites/Terran.png")
			sprite.scale = Vector2(1.5, 1.5)
			cell.add_child(sprite)

			# Label
			var label = Label.new()
			label.text = cell_chars[index]
			label.size = cell_size
			label.position = -cell_size / 2
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_constant_override("outline_size", 10)
			label.add_theme_font_override("font", font)
			label.add_theme_color_override("font_color", Color(0.0, 0.615, 0.0, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			cell.add_child(label)

			index += 1

func disable_quadrant(q: int):
	var selected = quadrants[q]
	for i in selected:
		if cells[i]:
			cells[i].modulate = Color(0.6, 0, 0)
			disabled_cells[i] = true
	await get_tree().create_timer(5).timeout
	for i in selected:
		if cells[i]:
			cells[i].modulate = Color(1, 1, 1)
			disabled_cells.erase(i)

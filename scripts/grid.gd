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
		[10,11,14,15]
	]

var cells := []
var disabled_cells := {}

func _ready():
	position = get_viewport().get_visible_rect().size / 2
	# Calculate total grid size to center it
	var total_width = cols * cell_size.x + (cols - 1) * cell_spacing.x
	var total_height = rows * cell_size.y + (rows - 1) * cell_spacing.y

	var start_x = -total_width / 2
	var start_y = -total_height / 2

	var index = 0
	for y in range(rows):
		for x in range(cols):
			# Create ColorRect
			var cell = ColorRect.new()
			cells.append(cell)
			cell.color = Color(0.2, 0.2, 0.2)  # dark gray
			cell.size = cell_size
			add_child(cell)

			# Position cell
			cell.position = Vector2(
				start_x + x * (cell_size.x + cell_spacing.x),
				start_y + y * (cell_size.y + cell_spacing.y)
			)

			# Add Label
			var label = Label.new()
			label.text = cell_chars[index]
			label.size = cell_size
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.size_flags_horizontal = Control.SIZE_FILL
			label.size_flags_vertical = Control.SIZE_FILL
			
			# Font
			label.add_theme_font_size_override("font_size", font_size)
			
			cell.add_child(label)

			index += 1


func disable_quadrant(q: int):
	var selected = quadrants[q]

	for i in selected:
		if cells[i]:
			cells[i].color = Color(0.6,0,0)
			disabled_cells[i] = true

	await get_tree().create_timer(5).timeout

	for i in selected:
		if cells[i]:
			cells[i].color = Color(0.2,0.2,0.2)
			disabled_cells.erase(i)

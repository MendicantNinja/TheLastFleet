extends Node2D
@onready var CombatMap: Node2D = $".."
@onready var PlayableAreaBounds: RectangleShape2D = $"../PlayableArea/PlayableAreaBounds".shape

var line_width: int = 30
var line_color: Color = Color8(25, 90, 255, 75)

func display_tactical_map() -> void:
	# Show the Tac Map
	CombatMap.tactical_camera()
	if self.visible == false:
		self.visible = true
		display()
	
	# Hide the Tac Map
	elif self.visible == true:
		for ship in CombatMap.ships_in_combat:
			ship.ship_select = false
		self.visible = false
		undisplay()
	

func undisplay() -> void:
	for ship in CombatMap.ships_in_combat:
		ship.TacticalMapIcon.hide()

func display() -> void:
	for ship in CombatMap.ships_in_combat:
		ship.TacticalMapIcon.show()
	

func _ready():
	pass # Replace with function body.

func _draw(): 
	var grid_square_size: int = 1000
	for i in range (PlayableAreaBounds.size.x/grid_square_size): #Draw Vertical N/S Lines
		draw_line(Vector2(i*grid_square_size, 0), Vector2(i*grid_square_size, PlayableAreaBounds.size.y), line_color, line_width, true) 
	
	for i in range (PlayableAreaBounds.size.y/grid_square_size): #Draw Horizontal W/E Lines
		draw_line(Vector2(0, i*grid_square_size), Vector2(PlayableAreaBounds.size.x, i*grid_square_size), line_color, line_width, true) 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
	

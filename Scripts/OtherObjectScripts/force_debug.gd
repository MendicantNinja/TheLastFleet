extends Node2D

var force_debug: bool = false
var separation_force: Vector2 = Vector2.ZERO
var cohesion_force: Vector2 = Vector2.ZERO
var goal_force: Vector2 = Vector2.ZERO
var avoidance_force: Vector2 = Vector2.ZERO

func _physics_process(delta):
	if force_debug == true:
		queue_redraw()

func _draw():
	var stupid: Transform2D = get_parent().transform
	draw_line(Vector2.ZERO, stupid.basis_xform_inv(avoidance_force), Color.RED)
	draw_line(Vector2.ZERO, stupid.basis_xform_inv(separation_force), Color.YELLOW)
	draw_line(Vector2.ZERO, stupid.basis_xform_inv(goal_force), Color.GREEN)
	draw_line(Vector2.ZERO, stupid.basis_xform_inv(cohesion_force), Color.DARK_ORANGE)

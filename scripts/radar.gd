extends Control
var game: Node3D
var timer := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		timer = 0.15
		queue_redraw()
func _point(position_value: Vector3) -> Vector2:
	return Vector2(103+position_value.x*1.4,103+position_value.z*1.4)
func _draw() -> void:
	if not is_instance_valid(game): return
	draw_rect(Rect2(0,0,206,206),Color(0.015,0.03,0.04,0.8))
	draw_rect(Rect2(0,0,206,206),Color("547a87"),false,1)
	draw_circle(Vector2(103,103),17,Color("4a5d63"))
	draw_rect(Rect2(98,119,10,30),Color("4a5d63"))
	draw_rect(Rect2(120,97,11,12),Color("4a5d63"))
	draw_rect(Rect2(64,93,21,20),Color("4a5d63"))
	for point in game.SITES:
		draw_circle(_point(point),6,Color(0.9,0.63,0.2,0.6))
	draw_string(ThemeDB.fallback_font,Vector2(98,107),"A",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(98,158),"B",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	for actor in get_tree().get_nodes_in_group("combatants"):
		if actor.health <= 0: continue
		if actor != game.player and actor.team != game.player.team and not game.has_sight(game.player,actor): continue
		draw_circle(_point(actor.global_position),3.2,Color("f1d68c") if actor == game.player else (Color("76c2d2") if actor.team == game.player.team else Color("e15f51")))
	var player_point := _point(game.player.global_position)
	var forward: Vector3 = -game.player.global_basis.z
	draw_line(player_point,player_point+Vector2(forward.x,forward.z)*8,Color("f1d68c"),2)

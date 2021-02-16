# Copyright © Dener Alves Silva - MIT License
tool
extends EditorPlugin

var mesh_paint: BrushMesh
var IsPainting := false
var brush
var interval = 1.0
var timer = 0.0

	

func _ready():
	set_input_event_forwarding_always_enabled()
	
func _enter_tree():
	print("hashsdhads")

func edit(object: Object) -> void:
	mesh_paint = object
	

func make_visible(visible: bool) -> void:
	# Called when the editor is requested to become visible.
	if not mesh_paint:
		return
	if not visible:
		mesh_paint = null

func handles(object: Object) -> bool:
	return object is BrushMesh



#align the cursor to the terrain
func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
	
	
func forward_spatial_gui_input(camera, event) -> bool:
	if not mesh_paint or not mesh_paint.visible:
		return false 

	brush = mesh_paint.get_child(0)
	
	if event is InputEventMouseMotion:
		
		var position2D = event.position
		var from = camera.project_ray_origin(event.position)
		var to   = from + camera.project_ray_normal(event.position) * 1000
		var space_state = mesh_paint.get_world().direct_space_state
		var position3D = space_state.intersect_ray(from,to)
		var t
		
		
		if (position3D.size() == 0):
			return false
			
		
		if (mesh_paint.paint or mesh_paint.delete):
			brush.transform.origin = position3D.position
			#Adjust the normal using the collision point
			t = align_with_y(brush.transform, position3D.normal)
			brush.transform.basis = t.basis.scaled(Vector3(mesh_paint.radius, mesh_paint.radius, mesh_paint.radius))
		
		if (IsPainting):
			timer += 0.5
			if timer >= interval:
				if (mesh_paint.delete):
					mesh_paint.DeleteMesh(position3D.position)
				else:
					mesh_paint.PaintMesh(position3D.position, position3D.normal, from, to)
				timer = 0.0

	if (event is InputEventMouseButton and event.button_index == BUTTON_LEFT):
		if event.is_pressed():
			IsPainting = true
			var position2D = event.position
			var from = camera.project_ray_origin(event.position)
			var to   = from + camera.project_ray_normal(event.position) * 1000
			var space_state = mesh_paint.get_world().direct_space_state
			var position3D = space_state.intersect_ray(from,to)
			return true
		else:
			IsPainting = false
			return false
			
	return false
	
		

# Copyright © Dener Alves Silva - MIT License
tool
extends MultiMeshInstance

class_name BrushMesh

const cursor_material = preload("res://addons/Material/cursor_material.tres")
const turret = preload("res://addons/Meshes/Turret.obj")

export(bool) var paint = false setget setPaint
export(bool) var delete = false setget setDelete
export(float, 0.5, 15) var radius = 1.0 setget setRadius
export(int, 10, 5000) var visible_instance_count = 3000 setget setVisibleCount
export(float, 0.1, 1.0) var min_scale = 0.5 setget setMinScale
export(float, 0.5, 3.0) var max_scale = 0.8 setget setMaxScale
export(bool) var clearAll = false setget setClear
var size_action = false
export(int, 1, 15) var density = 1 setget setDensity

var positions = []
var rotations = []
var scales = []
var qtd_multimesh = []
var brush
var mesh_scale

func setPaint(value) -> void:
	paint = value
	if (paint):
		get_child(0).visible = true
	else:
		if (!delete):
			get_child(0).visible = false
	
func setDelete(value) -> void:
	delete = value
	if (delete):
		get_child(0).visible = true
	else:
		if (!paint):
			get_child(0).visible = false

func _enter_tree():
	self.set_meta("_edit_lock_", true)
	brush = MeshInstance.new()
	brush.mesh = PlaneMesh.new()
	brush.name = "Brush"
	brush.material_override = cursor_material
	add_child(brush)
	brush.set_owner(get_tree().get_edited_scene_root())
	brush.visible = false
	
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = turret
	self.multimesh = multimesh

func setVisibleCount(value) -> void:
	visible_instance_count = value
	self.multimesh.visible_instance_count = value

func setRadius(value) -> void:
	radius = value
	brush = get_child(0)
	if (brush == null):
		return
	brush.transform.basis = Basis().scaled(Vector3(value + 0.5, 0, value + 0.5))
	
			
func setMinScale(valor) -> void:
	min_scale = valor
	scales.clear()
	
	for x in range(positions.size()):
		var rand_scale = rand_range(min_scale, max_scale)
		mesh_scale = rand_scale
		scales.append(mesh_scale)
		var align = align_with_y(Transform(brush.transform.basis, positions[x]), rotations[x])
		var b = align.basis.scaled(Vector3(scales[x], scales[x], scales[x]))
		var t = Transform(b, positions[x])
		self.multimesh.set_instance_transform(x, t)
	
	
func setMaxScale(valor) -> void:
	max_scale = valor
	scales.clear()
	
	for x in range(positions.size()):
		var rand_scale = rand_range(min_scale, max_scale)
		mesh_scale = rand_scale
		scales.append(mesh_scale)
		var align = align_with_y(Transform(brush.transform.basis, positions[x]), rotations[x])
		var b = align.basis.scaled(Vector3(scales[x], scales[x], scales[x]))
		var t = Transform(b, positions[x])
		self.multimesh.set_instance_transform(x, t)
		#var rand_scale = rand_range(min_scale, max_scale)
		#mesh_scale = rand_scale
		#scales.append(mesh_scale)
		#self.multimesh.get_instance_transform(x).basis.scaled(Vector3(mesh_scale, mesh_scale, mesh_scale))
		
		#var b = Basis(Vector3(mesh_scale, 0, 0), Vector3(0,mesh_scale, 0), Vector3(0,0,mesh_scale)).rotated(Vector3(rotations[x].z, rotations[x].y, -rotations[x].x), deg2rad(90))
		#var t = Transform(b, positions[x])
		
		#self.multimesh.set_instance_transform(x, t)
			

func setDensity(value) -> void:
	density = value

func setClear(value) -> void:
	clearAll = value
	positions.clear()
	rotations.clear()
	self.multimesh.instance_count = 0

func PaintMesh(value, rot, from, to) -> void:
	if not Engine.editor_hint:
		return
	if (value == null):
		return
	if (paint):
		for x in range(density):
			var space_state = get_tree().get_root().get_world().direct_space_state
			var rand_ray = rand_range(-radius, radius)
			var rand_rayz = rand_range(-radius, radius)
			var position3D = space_state.intersect_ray(from + Vector3(rand_ray,rand_ray,rand_rayz),to + Vector3(rand_ray,rand_ray,rand_rayz))
			
			if (position3D.size() == 0):
				return	
		
			var randPos = Vector3()
			multimesh.instance_count += 1
			var distance = radius 
			randPos = Vector3(position3D.position.x, position3D.position.y, position3D.position.z)	
			
			positions.append(randPos)
			rotations.append(rot)
			var rand_scale = rand_range(min_scale, max_scale)
			scales.append(rand_scale)
			updatePos()
			
func DeleteMesh(value) -> void:
	if not Engine.editor_hint:
		return
	if (delete):
		for x in range(positions.size()):
			if (x >= positions.size()):
				return
			var dist = positions[x].distance_to(value)
			if (dist <= radius):
				positions.remove(x)
				rotations.remove(x)
				scales.remove(x)
				self.multimesh.instance_count -= 1
				updatePos()
				
func updatePos() -> void:
	for x in range(positions.size()):
		#var b = Basis(Vector3(scales[x], 0, 0), Vector3(0,scales[x], 0), Vector3(0,0,scales[x]))#.rotated(Vector3(rotations[x].x, rotations[x].y, rotations[x].z), deg2rad(90))
		var align = align_with_y(Transform(brush.transform.basis, positions[x]), rotations[x])
		var b = align.basis.scaled(Vector3(scales[x], scales[x], scales[x]))
		var t = Transform(b, positions[x])
		self.multimesh.set_instance_transform(x, t)
	
func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
	
		
	





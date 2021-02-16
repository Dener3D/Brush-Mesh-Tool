tool
extends MultiMeshInstance

class_name BrushMesh

const cursor_material = preload("res://addons/brush_mesh/Material/cursor_material.tres")

export(Mesh) var mesh_obj = null setget setMesh
export(Material) var material = null setget setMaterial
export(bool) var paint = false setget setPaint
export(bool) var delete = false setget setDelete
export(float, 0.5, 15) var radius = 1.0 setget setRadius
export(float, 0.1, 1.0) var min_scale = 0.5 setget setMinScale
export(float, 0.5, 3.0) var max_scale = 0.8 setget setMaxScale
export(bool) var random_rotation = false setget setRandomRotation
export(int, 10, 5000) var visible_instance_count = 3000 setget setVisibleCount
export(bool) var clearAll = false setget setClear
var size_action = false
export(int, 1, 15) var density = 1 setget setDensity
export(String) var multimesh_name = ""
export(bool) var save = false setget setSave


var positions = []
var positionsLOD = []
var rotationsLOD = []
var rotations = []

var scales = []
var qtd_multimesh_obj = []
var brush
var mesh_obj_scale
var _from
var mesh_scale

func _enter_tree():
	connect("tree_entered", self, "_on_tree_entered")
	self.set_meta("_edit_lock_", true)
	
	if (brush == null):
		brush = MeshInstance.new()
		brush.mesh = PlaneMesh.new()
		brush.name = "Brush"
		brush.material_override = cursor_material
		brush.transform.origin = Vector3(0,0,0)
		add_child(brush)
		brush.visible = false
		brush.get_parent().move_child(brush, 0)
		
		var _multimesh = MultiMesh.new()
		_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		if (self.multimesh == null):
			self.multimesh = _multimesh
	

func setMesh(value) -> void:
	mesh_obj = value
	self.multimesh.mesh = value
	if (material != null):
		self.multimesh.mesh.surface_set_material(0, material)
	
func setMaterial(value) -> void:
	material = value
	self.multimesh.mesh.surface_set_material(0, value)

func setPaint(value) -> void:
	if not Engine.editor_hint:
		return
	paint = value
	if (paint and brush != null):
		brush.visible = true
	else:
		if (!delete and brush != null):
			brush.visible = false
	
func setDelete(value) -> void:
	if not Engine.editor_hint:
		return
	delete = value
	if (delete):
		brush.visible = true
	else:
		if (!paint):
			brush.visible = false
	

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

func setRandomRotation(value) -> void:
	random_rotation = value
	updatePos()

func setDensity(value) -> void:
	density = value

func setClear(value) -> void:
	clearAll = value
	if (value):
		positions.clear()
		rotations.clear()
		scales.clear()
		self.multimesh.instance_count = 0
			

func PaintMesh(value, rot, from, to) -> void:
	if not Engine.editor_hint:
		return
	_from = from
	if (value == null):
		return
	if (paint):
		for x in range(density):
			var space_state = get_tree().get_root().get_world().direct_space_state
			var rand_ray = rand_range(-radius, radius)
			var rand_rayz = rand_range(-radius, radius)
			var position3D = space_state.intersect_ray(Vector3(from.x + rand_ray, from.y, from.z + rand_rayz),to)
			
			if (position3D.size() == 0):
				return	

			var randPos = Vector3()
			var distance = radius 
			randPos = Vector3(position3D.position.x, position3D.position.y, position3D.position.z)	
			var rand_scale = rand_range(min_scale, max_scale)
			
			scales.append(rand_scale)
			positions.append(randPos)
			rotations.append(position3D.normal)
			self.multimesh.instance_count += 1
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
	pass
	for x in range(positions.size()):
		var align = align_with_y(Transform(self.multimesh.get_instance_transform(x).basis, positions[x]), rotations[x])
		var b = align.basis.scaled(Vector3(scales[x], scales[x], scales[x]))
		var t = Transform(b, positions[x])
		self.multimesh.set_instance_transform(x, t)
		
		
				
func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	var b = xform.basis.rotated(xform.basis.y.normalized(), rand_range(-PI/2, PI/2))
	if (random_rotation):
		xform.basis = b
	return xform

func setSave(value) -> void:
	save = value
	
	if value:
		if (multimesh_name == ""):
			print("The multimesh name is required for saving!")
		else:
			var mti = MultiMeshInstance.new()
			mti.name = multimesh_name
			mti.multimesh = MultiMesh.new()
			mti.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			mti.multimesh.mesh = mesh_obj
			#mti.multimesh.mesh.surface_set_material(0, material)
			mti.material_override = material
			mti.multimesh.instance_count = self.multimesh.instance_count
			for i in range(self.multimesh.instance_count):
				mti.multimesh.set_instance_transform(i, self.multimesh.get_instance_transform(i))
			add_child(mti)
			mti.set_owner(get_tree().get_edited_scene_root())
			positions.clear()
			rotations.clear()
			scales.clear()
			self.multimesh.instance_count = 0 
			save = false
			multimesh_name = ""

func _on_tree_entered():
	save = false
	paint = false
	delete = false
	
	brush = get_child(0)
	print("Enter Tree signal connected")
	
	positions.clear()
	rotations.clear()
	if (multimesh.mesh == null):
		multimesh.mesh = mesh_obj

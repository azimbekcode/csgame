extends RefCounted
## Original low-poly weapon models and synthesized effects; no CS assets used.

const DATA := {
	"pistol": {"name": "Pistol", "price": 0, "damage": 26, "mag": 12, "reserve": 72, "delay": 0.24, "reload": 1.7, "spread": 0.009, "auto": false},
	"ak": {"name": "AK-47", "price": 2700, "damage": 36, "mag": 30, "reserve": 90, "delay": 0.1, "reload": 2.4, "spread": 0.016, "auto": true},
	"m4": {"name": "M4", "price": 3100, "damage": 31, "mag": 30, "reserve": 90, "delay": 0.09, "reload": 2.2, "spread": 0.012, "auto": true},
	"mp5": {"name": "MP5", "price": 1500, "damage": 23, "mag": 30, "reserve": 120, "delay": 0.075, "reload": 1.9, "spread": 0.019, "auto": true},
	"awp": {"name": "Sniper", "price": 4750, "damage": 105, "mag": 5, "reserve": 25, "delay": 1.3, "reload": 2.8, "spread": 0.002, "auto": false},
	"shotgun": {"name": "Shotgun", "price": 1700, "damage": 14, "mag": 8, "reserve": 32, "delay": 0.85, "reload": 2.7, "spread": 0.07, "auto": false},
	"knife": {"name": "Knife", "price": 0, "damage": 45, "mag": -1, "reserve": 0, "delay": 0.45, "reload": 0.0, "spread": 0.0, "auto": true},
	"he": {"name": "HE grenade", "price": 300, "damage": 95, "mag": 1, "reserve": 0, "delay": 1.0, "reload": 0.0, "spread": 0.0, "auto": false},
	"flash": {"name": "Flash", "price": 200, "damage": 0, "mag": 1, "reserve": 0, "delay": 1.0, "reload": 0.0, "spread": 0.0, "auto": false},
	"smoke": {"name": "Smoke", "price": 300, "damage": 0, "mag": 1, "reserve": 0, "delay": 1.0, "reload": 0.0, "spread": 0.0, "auto": false}}


static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	return mat


static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


static func make_model(id: String) -> Node3D:
	var model := Node3D.new()
	var steel := material(Color("28313c"))
	var stock := material(Color("916544") if id == "ak" else Color("35424b"))
	var hand := material(Color("ad8065"))
	if id in ["he", "flash", "smoke"]:
		box(model, Vector3.ZERO, Vector3(0.09, 0.13, 0.09), material(Color("668451") if id == "he" else Color("929eac")))
		box(model, Vector3(0,0.085,0), Vector3(0.055,0.04,0.04), steel)
	elif id == "knife":
		box(model, Vector3(0,0,0.04), Vector3(0.04,0.045,0.17), steel)
		box(model, Vector3(0,0,-0.12), Vector3(0.018,0.065,0.2), material(Color("b1bac2")))
	elif id == "pistol":
		box(model, Vector3(0,0.045,-0.06), Vector3(0.06,0.07,0.24), steel)
		box(model, Vector3(0,-0.035,0.005), Vector3(0.055,0.12,0.08), stock)
		box(model, Vector3(0,0.09,-0.13), Vector3(0.015,0.018,0.035), steel)
	else:
		box(model, Vector3(0,0,-0.1), Vector3(0.065,0.08,0.28), steel)
		box(model, Vector3(0,-0.02,0.1), Vector3(0.07,0.08,0.18), stock)
		box(model, Vector3(0,-0.055,-0.09), Vector3(0.055,0.14,0.07), steel)
		box(model, Vector3(0,0.005,-0.32), Vector3(0.072,0.072,0.17), stock)
		box(model, Vector3(0,0.02,-0.47), Vector3(0.025,0.025,0.2), steel)
		box(model, Vector3(0,0.065,-0.39), Vector3(0.02,0.06,0.02), steel)
		if id == "awp":
			box(model, Vector3(0,0.09,-0.15), Vector3(0.06,0.055,0.19), steel)
	box(model, Vector3(0.02,-0.1,0.1), Vector3(0.06,0.06,0.16), hand)
	return model


static func sound(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.14 if kind == "shot" else 0.1
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for index in range(count):
		var time := float(index) / rate
		var envelope := exp(-time * (38.0 if kind == "shot" else 28.0))
		var value := (rng.randf_range(-1,1) * 0.7 + sin(time * 650.0) * 0.3) if kind == "shot" else sin(time * 2100.0) * 0.4
		bytes.encode_s16(index * 2, int(value * envelope * 23000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

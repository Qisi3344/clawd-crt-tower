class_name CrabAvatar
extends Node3D

# Ratios are from Qisi3344/clawd-motion public/clawd.json, not a generic crab.
var body: Node3D
var claws: Array[Node3D] = []
var legs: Array[Node3D] = []
var time := 0.0

func _ready() -> void:
	var orange := Color("d97757")
	body = Node3D.new()
	add_child(body)
	Craft.box(body, Vector3(0,0.62,0), Vector3(1.0,0.78,0.675), orange, 0.065)
	for side in [-1,1]:
		var claw := Node3D.new()
		claw.position = Vector3(side * 0.60,0.51,0.04)
		body.add_child(claw)
		Craft.box(claw, Vector3.ZERO, Vector3(0.22,0.20,0.22), orange, 0.035)
		claws.append(claw)
		Craft.box(body, Vector3(side * 0.20,0.69,0.344), Vector3(0.085,0.22,0.018), Color("2e3a5c"), 0.008)
		Craft.box(body, Vector3(side * 0.20-0.015,0.75,0.358), Vector3(0.025,0.045,0.008), Color("fbfdff"), 0.002, 0.2)
	for x in [-0.40,-0.15,0.15,0.40]:
		var leg := Node3D.new()
		leg.position = Vector3(x,0.30,0.18)
		add_child(leg)
		Craft.box(leg, Vector3(0,-0.13,0), Vector3(0.17,0.28,0.17), Color("c9694b"), 0.028)
		legs.append(leg)

func animate(delta: float, speed: float, attack: float, hurt: float, airborne: bool) -> void:
	time += delta
	var walk: float = minf(speed / 4.5, 1)
	body.position.y = sin(time * 3.2) * 0.012 + absf(sin(time * 15)) * walk * 0.045
	body.rotation.z = sin(time * 14) * walk * 0.035
	body.scale = Vector3(1.0 + hurt * 0.1, 1.0 - hurt * 0.14, 1)
	for i in range(4):
		var phase: float = time * 15 + (i % 2) * PI
		legs[i].rotation.x = sin(phase) * walk * 0.55
		legs[i].position.y = 0.30 + maxf(0,sin(phase)) * walk * 0.09 + (0.08 if airborne else 0)
	for i in range(2):
		claws[i].rotation.z = (1 if i == 0 else -1) * (sin(time * 2.8) * 0.07 + attack * 1.4)
		claws[i].position.z = 0.04 + attack * 0.5

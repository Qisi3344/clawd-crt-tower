class_name ControlRouter
extends Node

var profile: ControlProfile
var allowed := false
var sources: Dictionary={}
var edges: Dictionary={}
var mouse_attack := false

func set_source(id: int, actions: Dictionary) -> void:
	var before:=virtual_actions()
	if actions.is_empty(): sources.erase(id)
	else: sources[id]=actions
	var after:=virtual_actions()
	for action in after:
		if float(after[action])>0 and float(before.get(action,0))<=0: edges[action]=true

func virtual_actions() -> Dictionary:
	var result:Dictionary={}
	for actions in sources.values():
		for action in actions: result[action]=maxf(float(result.get(action,0)),float(actions[action]))
	return result

func strength(action: String) -> float:
	if not allowed: return 0
	var physical:float=Input.get_action_strength(action) if profile.profile=="keyboard" else 0
	return maxf(physical,float(virtual_actions().get(action,0)))

func axis(negative: String, positive: String) -> float: return strength(positive)-strength(negative)
func pressed(action: String) -> bool: return strength(action)>.2
func just_pressed(action: String) -> bool:
	if not allowed: return false
	var edge:bool=edges.get(action,false)
	edges.erase(action)
	if action=="attack" and mouse_attack: edge=true;mouse_attack=false
	return edge or (profile.profile=="keyboard" and Input.is_action_just_pressed(action))

func release_all() -> void:
	sources.clear();edges.clear();mouse_attack=false

func _unhandled_input(event: InputEvent) -> void:
	if allowed and profile.profile=="keyboard" and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		mouse_attack=true;get_viewport().set_input_as_handled()

extends Node


var peer = null
var player_name = "admin"
var players = {}
const DEFAULT_PORT = 10567
const MAX_PEER = 12

signal player_list_changed()
signal game_error(what)
signal game_ended()
signal connection_succeeded()
signal connection_failed()
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("network_peer_connected",self,"_player_connected")
	get_tree().connect("network_peer_disconnected",self,"_player_disconnected")
	get_tree().connect("connected_to_server",self,"_connected_ok")
	get_tree().connect("connection_failed",self,"_connected_fail")
	get_tree().connect("server_disconnected",self,"_server_disconnected")

func _player_connected(id):
	rpc_id(id,"register_player",player_name)
	print("_player_connected")

func _player_disconnected(id):
	print("_player_disconnected")	
	if has_node("/root/World") && get_tree().is_network_server():
		emit_signal("game_error","Player " + players[id] + " disconnected")
		end_game()
	else:
		unregister_player(id)

func _connected_ok():
	print("_connected_ok")		
	emit_signal("connection_succeeded")

func _connected_fail():
	print("_connected_fail")			
	emit_signal("game_error","Server disconnected")
	end_game()

func _server_disconnected():
	print("_server_disconnected")				
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")

remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	players[id] = new_player_name
	emit_signal("player_list_changed")
	print("register_player" +  new_player_name)

func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")	

func host_game(new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT,MAX_PEER)
	get_tree().set_network_peer(peer)

func join_game(ip,new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip,DEFAULT_PORT)
	get_tree().set_network_peer(peer)

func get_player_list():
	return players.values()
	
func get_player_name():
	return player_name

func begin_game():
	assert(get_tree().is_network_server())
	
	var spawn_points = {}
	spawn_points[1] = 0
	var i = 1
	for player in players:
		spawn_points[player] = i
		i += 1
		
	for player in players:
		rpc_id(player, "pre_start_game", spawn_points)	
	pre_start_game(spawn_points)

func end_game():
	if has_node("/root/World"):
		get_node("/root/World").queue_free()
		
	emit_signal("game_ended")
	players.clear()

remote func pre_start_game(spawn_points):
	var world = load("res://world.tscn").instance()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

	print(spawn_points)
	var player_scene = load("res://Player/player.tscn")
	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		var player = player_scene.instance()

		player.set_name(str(p_id)) # Use unique ID as node name.
		player.position=spawn_pos
		player.set_network_master(p_id) #set unique id as master.

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player.set_player_name(player_name)
			
		else:
			# Otherwise set name from peer.
			player.set_player_name(players[p_id])

		world.get_node("MainYSort").get_node("Players").add_child(player)
		if p_id == get_tree().get_network_unique_id():
			var remoteTransform2D = RemoteTransform2D.new()
			remoteTransform2D.remote_path = "../../../Camera2D"
			player.add_child(remoteTransform2D)

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

func _player_disconnected(id):
	if has_node("/root/World") && get_tree().is_network_server():
		emit_signal("game_error","Player " + players[id] + " disconnected")
		end_game()
	else:
		unregister_player(id)

func _connected_ok():
	emit_signal("connection_succeeded")

func _connected_fail():
	emit_signal("game_error","Server disconnected")
	end_game()

func _server_disconnected():
	get_tree().set_network_peer(null)
	emit_signal("connection_failed")

remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	players[id] = new_player_name
	emit_signal("player_list_changed")

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

func end_game():
	if has_node("/root/World"):
		get_node("/root/World").queue_free()
		
	emit_signal("game_ended")
	players.clear()

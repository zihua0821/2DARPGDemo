extends Control

onready var connectPanel = $Connect
onready var nameInput = $Connect/Name
onready var IPinput = $Connect/IPAddress
onready var errLabel = $Connect/ErrorLabel

onready var playersPanel = $Players
onready var playersList = $Players/ItemList

onready var errDialog = $ErrorDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	Gamestate.connect("player_list_changed",self,"refresh_lobby")
	Gamestate.connect("game_error",self,"_on_game_error")
	Gamestate.connect("game_ended",self,"_on_game_ended")
	Gamestate.connect("connection_failed",self,"_on_connection_failed")
	Gamestate.connect("connection_succeeded",self,"_on_connection_succeeded")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Host_pressed():
	if nameInput.text == "":
		errLabel.text = "Invalid name!"
		errLabel.show()
		return
	
	errLabel.hide()
	connectPanel.hide()
	playersPanel.show()
	Gamestate.host_game(nameInput.text)
	refresh_lobby()
	


func _on_Join_pressed():
	if nameInput.text == "":
		errLabel.text = "Invalid name!"
		errLabel.show()
		return
	var ip = IPinput.text
	if not ip.is_valid_ip_address():
		errLabel.text = "Invalid IP address!"
		errLabel.show()
		return
	
	errLabel.hide()
	connectPanel.hide()
	playersPanel.show()
	Gamestate.join_game(ip,nameInput.text)	


func _on_Start_pressed():
	pass # Replace with function body.

func refresh_lobby():
	var players = Gamestate.get_player_list()
	players.sort()
	playersList.clear()
	playersList.add_item(Gamestate.get_player_name() + " (You)")
	for player in players:
		playersList.add_item(player)
	$Players/Start.disabled = not get_tree().is_network_server()

func _on_game_error(errtext):
	errDialog.dialog_text = errtext
	errDialog.popup_centered_minsize()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _on_game_ended():
	show()
	connectPanel.show()
	playersPanel.hide()
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false

func _on_connection_failed():
	$Connect/Host.disabled = false
	$Connect/Join.disabled = false
	errLabel.text = "Connection failed"
	errLabel.show()
	
func _on_connection_succeeded():
	connectPanel.hide()
	playersPanel.show()

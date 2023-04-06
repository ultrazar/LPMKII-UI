extends Node

# SessionData singleton
# In this singleton is where all the data of the satellite is being managed
# Manages downloaded files and all the received data

const userDataPath = "user://UserData.dat"

var sessionName : String = "Test session"
var sessionDirectoryPath : String  = ""


func storeUserData():
	var file = File.new()
	file.open(userDataPath, File.WRITE)
	

func readUserData():
	var file = File.new()
	if file.file_exists(userDataPath):
		file.open(userDataPath, File.READ)
		var content = file.get_as_text()
		file.close()
		return content
	else:
		pass


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

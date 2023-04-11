extends Node

# SessionData singleton
# In this singleton is where all the data of the satellite is being managed
# Manages downloaded files and all the received data

# Session directory structure 
# /.../Test_session/
#					F--> Session.dat --> {"Name":"<SessionName>","StartTime":<UnixStartTime>,"Stage":1/2/3}
#					D--> Logs/
#							F--> RawData.log
#							F--> Debug.log
#					D--> Files/
#							(... Files downloaded by the LPMKII)
#					D--> GraphData/
#							(CSV and jpg files created by the graph panel)


const userDataPath = "user://UserData.dat"
const sessionDataFileName = "Session.LPMKII"

enum {
	STAGE_1,
	STAGE_2,
	STAGE_3
}

var sessionName : String = "Test session"
var sessionDirectoryPath : String  = ""

var startTime : int # The Unix time when the LPMKII started up
var stage = STAGE_1

var rawDataLogFile : File
var debugDataLogFile : File

var csvFile : File
const csvParams = PoolStringArray(["time","temperature","humidity","pressure","altitude","GPS_altitude","longitude","latitude","lipo_voltage"])

enum {
  LEGS_CLOSED,
  LEGS_OPENING,
  LEGS_OPENED,
  LEGS_CLOSING
}

var legsState = LEGS_CLOSED

func storeRawBytes(bytes : PoolByteArray):
	rawDataLogFile.store_buffer(bytes)

func storeSessionData():
	var file = File.new()
	var path = sessionDirectoryPath + "/" + sessionDataFileName
	if not file.file_exists(path): # Create new session
		print("Creating new session...")
		stage = 0
		startTime = 0
		var dir = Directory.new()
		dir.make_dir(sessionDirectoryPath + "/Logs")
		file.open(sessionDirectoryPath + "/Logs/RawData.log",File.WRITE)
		file.close()
		file.open(sessionDirectoryPath + "/Logs/Debug.log",File.WRITE)
		file.close()
		dir.make_dir(sessionDirectoryPath + "/Files")
		dir.make_dir(sessionDirectoryPath + "/GraphData")
		file.open(sessionDirectoryPath + "/GraphData/All.csv",File.WRITE)
		file.store_line(csvParams.join(","))
		file.close()
	
	file.open(path,File.WRITE)
	var content = to_json({
		"Name":sessionName,
		"StartTime": startTime,
		"Stage": stage
	})
	file.store_line(content)
	file.close()
	print("Stored sessionData: " + content)
	

func getDownloadedFilePath(fileName):
	return sessionDirectoryPath  + "/Files/" + fileName

func getDownloadedFileWriter(fileName):
	var file = File.new()
	var path = getDownloadedFilePath(fileName)
	if (file.file_exists(path)):
		print("replacing file: " + fileName)
		var dir = Directory.new()
		dir.remove(path)
	file.open(path,File.WRITE)
	return file


func readSessionData(): # (Executed once in the startup)
	var path = sessionDirectoryPath + "/" + sessionDataFileName
	var file = File.new()
	file.open(path,File.READ)
	var content = JSON.parse(file.get_line()).result
	sessionName = content["Name"]
	startTime = content["StartTime"]
	stage = content["Stage"]
	print("Loaded SessionData: " + str(content))
	rawDataLogFile = File.new()
	print(rawDataLogFile.open(sessionDirectoryPath + "/Logs/RawData.log",File.READ_WRITE))
	rawDataLogFile.seek_end()
	debugDataLogFile = File.new()
	debugDataLogFile.open(sessionDirectoryPath + "/Logs/Debug.log",File.READ_WRITE)
	debugDataLogFile.seek_end()
	csvFile = File.new()
	csvFile.open(sessionDirectoryPath + "/GraphData/All.csv",File.READ_WRITE)
	csvFile.seek_end()
	
	SerialTransceiverProtocol.setMissionPhase(SerialTransceiverProtocol.PHASE_AIR if stage == STAGE_2 else SerialTransceiverProtocol.PHASE_STATIONED)
	nextStage(stage)

func storeUserData(): # Executed only when changing (or creating) the session
	var file = File.new()
	file.open(userDataPath, File.WRITE)
	var content = to_json({"sessionDirectoryPath":sessionDirectoryPath})
	file.store_line(content)
	file.close()
	storeSessionData()
	readSessionData()
	print("Saved UserData: " + content)
	

func readUserData():
	var file = File.new()
	if file.file_exists(userDataPath):
		file.open(userDataPath, File.READ)
		var content = JSON.parse(file.get_line() ).result
		sessionDirectoryPath = content["sessionDirectoryPath"]
		file.close()
		print("Loaded UserData: " + str(content))
		readSessionData()
		
	else:
		var EditSessionNode : AcceptDialog = get_tree().current_scene.get_node("EditSession")
		EditSessionNode.popup()
		EditSessionNode.window_title = "Create a new session"

func nextStage(newStage):
	stage = newStage
	get_tree().current_scene.updateSessionConfigPanel()
	storeSessionData()


var flushTimer : Timer # A flush timer to save the data repeatedly
const flushInterval = 1

func flushData(): 
	rawDataLogFile.flush()
	debugDataLogFile.flush()
	csvFile.flush()

func _ready():
	readUserData()
	flushTimer = Timer.new()
	flushTimer.wait_time = flushInterval
	flushTimer.autostart = true
	self.add_child(flushTimer)
	flushTimer.connect("timeout",self,"flushData")



extends Node
# SerialTransceiverProtocol - Singleton (Global variable)
# Manages the serial communication for the Transceiver and the LPMKII protocol


const SERCOMM = preload("res://bin/GDsercomm.gdns")# for linux: preload("res://addons/GDSerCommDock/bin/GDSerComm.gdns")
onready var PORT = SERCOMM.new()

const baudrates = [300,600,1200,2400,4800,9600,14400,19200,28800,38400,57600,115200]
var port
var connected : bool = false
var debugTerminal : RichTextLabel

enum  {
	PHASE_AIR,
	PHASE_STATIONED
}

var missionPhase = PHASE_AIR

func _ready():
	self.pause_mode = Node.PAUSE_MODE_PROCESS

enum {
	PRINT_RX,
	PRINT_TX,
	PRINT_TELEMETRY
}

func printDebugData(text):
	var line = Time.get_time_string_from_system() + " - " + text + "\n"
	debugTerminal.text += line
	if (SessionData.debugDataLogFile):
		SessionData.debugDataLogFile.store_string(line)

func setMissionPhase(phase):
	missionPhase = phase
	var label = get_tree().current_scene.get_node("Main/Panel/Top_options/missionPhaseLabel")
	debugTerminal = get_tree().current_scene.get_node("Main/Middle/TabContainer/Device data/HBoxContainer/VBoxContainer/DebugText")
	buffer = ""
	if phase == PHASE_AIR:
		label.text = "Mission phase 1 - Ascent and descense"
		label.modulate = Color("68ff00")
		printDebugData("TEL: PHASE CHANGED TO PHASE_AIR")
	elif phase == PHASE_STATIONED:
		label.text = "Mission phase 2 - Stationed command control"
		label.modulate  = Color("00f9ff")
		printDebugData("TEL: PHASE CHANGED TO PHASE_STATIONED")
	else:
		label.text = "ERROR"
		label.modulate = Color("ff0000")

func set_connected(value : bool):
	connected = value
	if value:
		get_tree().paused = false
		get_tree().current_scene.get_node("Main/Middle").modulate = Color("ffffff")
		get_tree().current_scene.get_node("Main/Graph").modulate = Color("ffffff")
	else:
		get_tree().paused = true
		get_tree().current_scene.get_node("Main/Middle").modulate = Color("626262")
		get_tree().current_scene.get_node("Main/Graph").modulate = Color("626262")

func sendLine(line):
	PORT.write(line + "\n")

#--------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------
#-------------------------------- PHASE AIR CODE --------------------------------------
#--------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------

func arduinohex_to_int(hex):
	#  12345678 --> 0x78563412 
	if (len(hex) != 8):
		return 0
	return ("0x" + hex[6] + hex[7] + hex[4] + hex[5] + hex[2] + hex[3] + hex[0] + hex[1]).hex_to_int()

"""
struct tx_packet { // The sructure of the Lancelot TX data packets
  unsigned int protocol = 0x78563412;
  unsigned int time;
  unsigned int temperature; 
  unsigned int pressure; 
  unsigned int humidity; 
  unsigned int latitude; 
  unsigned int longitude; 
  unsigned int GPS_altitude;
  unsigned int sattelites;
  unsigned int lipo_voltage; 
 };
tx_packet create_packet() {
  tx_packet result;
  result.time = millis();
  result.temperature = temperature * 100 + 10000;
  result.pressure = pressure * 10;
  result.humidity = humidity * 100;
  result.latitude = latitud*(100000) + (1000000000);
  result.longitude = longitud*(100000) + (1000000000);
  result.GPS_altitude = GPS_altitude;
  result.sattelites = sat;
  result.lipo_voltage = lipo_voltage * 100;
  return result;
"""

var LPMKII_DATA = {
	"time": 0.0,
	"temperature": 0.0,
	"pressure":0.0,
	"humidity":0.0,
	"latitude":0.0,
	"longitude":0.0,
	"GPS_altitude":0.0,
	"satellites":0.0,
	"lipo_voltage":0.0,
	"altitude": 0.0
}
var buffer = ""

func update_vars(hex):
	set_connected(true)

	var arr = []
	if hex.length() != 72:
		return
	for i in range(9):
		var temp = ""
		for i2 in range(8):
			temp += hex[i2 + (i*8)]
		arr.append(arduinohex_to_int(temp))
	LPMKII_DATA["time"] = arr[0]
	LPMKII_DATA["temperature"] = (arr[1] -10000) / 100.0
	LPMKII_DATA["pressure"] = arr[2]/10.0
	LPMKII_DATA["humidity"] = arr[3]/100.0
	LPMKII_DATA["latitude"] = (arr[4] -1000000000)/100000.0
	LPMKII_DATA["longitude"] = (arr[5] -1000000000)/100000.0
	LPMKII_DATA["GPS_altitude"] = arr[6]
	LPMKII_DATA["satellites"] = arr[7]
	LPMKII_DATA["lipo_voltage"] = arr[8]/100.0
	
	# Calculate height from the pressure
	var altitude = 44330 * (1.0 - pow((LPMKII_DATA["pressure"] / 100) / 1013.25, 0.1903));
	LPMKII_DATA["altitude"] = int(altitude)
	
	printDebugData("New packet: " + str(LPMKII_DATA))
	
	var csvLine = PoolStringArray([])
	for i in SessionData.csvParams:
		csvLine.append(str(LPMKII_DATA[i]) )
	SessionData.csvFile.store_line(csvLine.join(","))
	
	if SessionData.startTime == 0: # Define the startTime from the packet
		SessionData.startTime = int(Time.get_unix_time_from_system() - LPMKII_DATA["time"])


func _physics_process(delta): 
	if PORT.get_available()>0:
		if downloading:
			readDownloadBytes()
			return
			
		if missionPhase == PHASE_AIR:
			for i in range(PORT.get_available()):
				var actual = PoolByteArray([PORT.read(true)])
				SessionData.storeRawBytes(actual)
				actual = actual.hex_encode()
				buffer += actual
				var spl = buffer.split("12345678")
				if len(spl) == 2:
					if spl[0] != "":
						print(spl[0].length())
						update_vars(spl[0])
					buffer = spl[1]
		else: # PHASE_STATIONED DATA PROCESSING
			for i in range(PORT.get_available()):
				var actual = PoolByteArray([PORT.read(true)]) # Reads a char from the serial buffer
				SessionData.storeRawBytes(actual)
				actual = actual.get_string_from_ascii()
				if typeof(actual) == TYPE_STRING:
					if actual == "\n" or actual == "\r":
						if buffer.length() != 0:
							processStationedLine(buffer)
						buffer = ""
					else:
						buffer += actual
				else:
					print("CHARACHTER LOST: " + str(actual))


#--------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------
#-------------------------------- PHASE STATIONED CODE --------------------------------
#--------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------

var files = {} # "FileName": [FileSize,isDownloaded]
var ItemListNode : ItemList
var unknownIcon = preload("res://sprites/unknown.jpg")

func reloadFilesItems():
	ItemListNode.clear()
	for i in files:
		var icon = unknownIcon
		if files[i].size() == 3: # If downloaded
			icon = files[i][2]
		ItemListNode.add_item(i + (" (%s)" % str(files[i][0]) ),icon )
	get_tree().current_scene.get_node("Main/Middle/TabContainer/Files/noItemsAvailableLabel").visible = (files.size() == 0)

var downloadWindowDialog : WindowDialog

var downloading = false
var goingToDownload = false
var fileDownloading = ""
var fileBytesLeft = 0.0
var fileSize = 0.0
var startDownloadTime = 0.0 # Unix time of the start of the download to know the dw speed
var fileBuffer = PoolByteArray()

const downloadingDialog = \
"""Downloading %s file...

%s/%s bytes received  %s bytes/second
"""

func updateDownloadDialog():
	downloadWindowDialog.get_node("Label").text = downloadingDialog % [
		fileDownloading, 
		str(fileSize - fileBytesLeft), str(fileSize),
		str( int((fileSize - fileBytesLeft) / ( 1 + (Time.get_unix_time_from_system() - startDownloadTime) ) ) ) # speed
	]
	downloadWindowDialog.get_node("ProgressBar").max_value = fileSize
	
	downloadWindowDialog.get_node("ProgressBar").value = fileSize - fileBytesLeft

func downloadFile(fileName:String):
	if not fileName in files:
		return
	goingToDownload = true
	fileDownloading = fileName
	downloadWindowDialog = get_tree().current_scene.get_node("WindowDialog")
	sendLine("/D;" + fileName) # /D;<FileName>


func processDownloadedFile():
	"""
	var file : File = File.new()
	var path = "user://" + fileDownloading
	if (file.file_exists(path)):
		var dir = Directory.new()
		dir.remove(path)
	file.open(path,File.WRITE)
	"""
	var file : File = SessionData.getDownloadedFileWriter(fileDownloading)
	file.store_buffer(fileBuffer)
	file.close()
	files[fileDownloading][1] = true
	downloadWindowDialog.hide()
	
	if (fileDownloading.ends_with(".jpg")):
		var image = Image.new()
		image.load(SessionData.getDownloadedFilePath(fileDownloading))
		var icon  = ImageTexture.new()
		icon.create_from_image(image)
		files[fileDownloading].append(icon)
	reloadFilesItems()


func readDownloadBytes():
	for byte in range(PORT.get_available()):
		fileBuffer.push_back(PORT.read(true))
		fileBytesLeft -= 1
	
	if fileBytesLeft <= 0:
		downloading = false
		print("DOWNLOAD COMPLETED")
		processDownloadedFile()
	
	updateDownloadDialog()

"""
void sendCameraSettigns(    bool enable, 
							unsigned short int interval_high, 
							unsigned short int interval_low, 
							unsigned int unix_time, 
							imageSize camera_res_high,
							imageSize camera_res_low,
							int jpeg_quality_high,
							int jpeg_quality_low) {

	String result = String(enable) + ";" + 
					String(interval_high) + ";" + 
					String(interval_low) + ";" + 
					String(unix_time) + ";" +
					String(camera_res_high) + ";" + 
					String(camera_res_low) + ";" + 
					String(jpeg_quality_high) + ";" +
					String(jpeg_quality_low);
	sendLine("C" + result);

	SYSTEMS     - SYNTAX: /S;<LEGS>;<SRV>;<BUZZER>;<LED;<GPS>;<FREQ>;<TX_PWR>
				
				bool LEGS
				int SRV;
				bool BUZZER;
				bool LED;
				bool GPS;
				int FREQ;
				int TX_PWR;

				- DESCRIPTION: Set the systems configuration
				- RESPONSE: !<ErrorNum>
"""

func sendSystemParams(
	LEGS,SRV:int,BUZZER:bool,LED:bool,GPS:bool,FREQ:int,TX_PWR:int):
	var result = "/S;" + \
					str(int(LEGS)) + ";" + \
					str(SRV) + ";" + \
					str(int(BUZZER)) + ";" + \
					str(int(LED)) + ";" + \
					str(int(GPS)) + ";" + \
					str(FREQ) + ";" + \
					str(TX_PWR)
	sendLine(result)
	printDebugData("TEL: Sending system params: " + result)

func sendCameraSettings(
	interval_1, interval_2,
	camera_res_1,camera_res_2,
	compression_1, compression_2 ):
	var result = "/C1;" + \
					str(interval_1) + ";" + \
					str(interval_2) + ";100;" + \
					str(camera_res_1) + ";" + \
					str(camera_res_2) + ";" + \
					str(compression_1) + ";" + \
					str(compression_2)
	sendLine(result)
	printDebugData("TEL: Sending camera settings: " + result)

func processStationedLine(line:String):
	set_connected(true)
	print(line)
	if "#STATIONED MODE ACTIVATED" in line:
		SessionData.nextStage(SessionData.STAGE_3)
		setMissionPhase(PHASE_STATIONED)
	
	elif line[0] == "#": # just a debug print
		printDebugData(line.substr(1))

	elif line.substr(0,2) == "R1": # PROCESS LS RESPONSE
		ItemListNode = get_tree().current_scene.get_node("Main/Middle/TabContainer/Files/ScrollContainer/ItemList")
		var fileList = line.substr(3).split(";", false) # "R1:<File1Name>,<File1Size>;<File2Name>,<File2Size>;..."
		for i in fileList:
			var prop = i.split(",")
			if prop.size() == 2:
				if not prop[0] in files:
					files[prop[0]] = [int(prop[1]),false]
		reloadFilesItems()
		printDebugData(line.substr(0))

	elif line.substr(0,2) == "DW": # START DOWNLOAD
		
		print("DOWNLOAD: " + line)
		fileSize = int(line.substr(2))
		fileBytesLeft = fileSize
		startDownloadTime = Time.get_unix_time_from_system()
		downloading = true
		goingToDownload = false
		fileBuffer = PoolByteArray()
		downloadWindowDialog.popup()
		updateDownloadDialog()
	elif line == "PHASE_AIR":
		SessionData.nextStage(SessionData.STAGE_2)
		setMissionPhase(PHASE_AIR)

func requestNextStage():
	missionPhase = PHASE_STATIONED # PHASE_STATIONED to read the ASCII response
	if (SessionData.stage == SessionData.STAGE_1 || SessionData.stage == SessionData.STAGE_3 ):
		sendLine("/A") # Request PHASE_AIR
	else:
		PORT.write("PHASE_STATIONED") # Request PHASE_STATIONED

func GetBaudrates():
	return baudrates

func SelectBaudrate(baudrate):
	#set_connected(false)
	set_physics_process(false)
	PORT.close()
	if port!=null:
		print(PORT.open(port,int(baudrate),1000,0,0,0))
		PORT.flush()
		print(port)
		print(baudrate)
	else:
		breakpoint
	set_physics_process(true)

func GetPortsList(): #Updates the port list
	var list=PORT.list_ports()
	if len(list) == 1:
		port=list[0]
	return list

func SelectPort(PortName):
	#set_connected(false)
	port=PortName

extends Node


onready var NodePortList = $Main/Panel/Top_options/SerialThings/Port
onready var NodeBaudrateList = $Main/Panel/Top_options/SerialThings/Baudoption


func _enter_tree():
	pass#SerialTransceiverProtocol.set_connected(false)

func _on_Port_pressed():
	NodePortList.clear()
	for item in SerialTransceiverProtocol.GetPortsList():
		NodePortList.add_item(str(item))
	


func _on_Baudoption_pressed():
	NodeBaudrateList.clear()
	for item in SerialTransceiverProtocol.GetBaudrates():
		NodeBaudrateList.add_item(str(item))


func _on_Port_item_selected(index):
	SerialTransceiverProtocol.SelectPort(NodePortList.get_item_text(index))
	$Main/Panel/Top_options/SerialThings/Port.selected = index
	print(NodePortList.get_item_text(index))


func _on_Baudoption_item_selected(index):
	SerialTransceiverProtocol.SelectBaudrate(NodeBaudrateList.get_item_text(index))
	$Main/Panel/Top_options/SerialThings/Baudoption.selected = index
	print(NodeBaudrateList.get_item_index(index))


func _on_reloadFilesButton_pressed():
	SerialTransceiverProtocol.sendLine("/L")

var fileToDownload = ""
var fileToDownloadSize
var transceiverSpeed = 400 # Bytes per second

const downloadConfirmationDialogText = \
"""Are you sure to download %s file? (%s bytes)
It will take %s seconds approximately...
"""


func _on_ItemList_item_activated(index):
	fileToDownload = $Main/Middle/TabContainer/Files/ScrollContainer/ItemList.get_item_text(index).split(" ")[0]
	fileToDownloadSize = SerialTransceiverProtocol.files[fileToDownload][0]
	var arr = SerialTransceiverProtocol.files[fileToDownload]
	if (arr[1]): # If it is already downloaded
		if (arr.size() == 3): # If it is an image
			$ImagePopup.popup()
			$ImagePopup.window_title = fileToDownload
			$ImagePopup/TextureRect.texture = arr[2]
			$ImagePopup.rect_size = arr[2].get_data().get_size()
		
	else: # Not downloaded, asking to download
		$ConfirmationDialog.dialog_text = downloadConfirmationDialogText % [fileToDownload,str(fileToDownloadSize),str(fileToDownloadSize / transceiverSpeed)]
		$ConfirmationDialog.popup()


func _on_ConfirmationDialog_confirmed():
	SerialTransceiverProtocol.downloadFile(fileToDownload)


func _on_FileDialog_dir_selected(dir):
	$EditSession/HBoxContainer2/VBoxContainer/HBoxContainer3/Label.text = dir
	var valid = Directory.new().dir_exists(dir)
	$EditSession.get_close_button().disabled = not valid
	$EditSession.dialog_hide_on_ok = valid
	SessionData.sessionDirectoryPath = dir
	if valid:
		if Directory.new().file_exists(dir + "/Session.LPMKII"): # If it is an existing session
			$EditSession/HBoxContainer2/VBoxContainer/Message/Label.text = "Selecting an existing session"
			$EditSession/HBoxContainer2/VBoxContainer/SessionName.hide()
		else:
			$EditSession/HBoxContainer2/VBoxContainer/Message/Label.text = "Creating a new session"
			$EditSession/HBoxContainer2/VBoxContainer/SessionName.show()

func _on_EditSessionName_text_changed(new_text):
	SessionData.sessionName  = new_text

func updateSessionConfigPanel():
	$"Main/Middle/LeftPanel/Session config".updatePanel()

var restartLPMKII = false
func _on_EditSession_confirmed():
	SessionData.storeUserData()
	updateSessionConfigPanel()
	if restartLPMKII:
		get_tree().quit()


func _on_ChangeSessionButton_pressed():
	get_tree().paused = true
	$EditSession.popup()
	$EditSession/HBoxContainer2/VBoxContainer/Alert/Label.show()
	$EditSession.window_title = "Change the actual session"
	restartLPMKII = true


func _ready():
	#SerialTransceiverProtocol.setMissionPhase(SerialTransceiverProtocol.PHASE_STATIONED)
	updateSessionConfigPanel()
	
	#Ser default transceiver config (/dev/ttyUSB0 115200)
	print("USING DEFAULT transceiver config (/dev/ttyUSB0 115200)")
	var list : Array = SerialTransceiverProtocol.GetPortsList()
	_on_Port_pressed()
	if "/dev/ttyUSB0" in list:
		_on_Port_item_selected(list.find("/dev/ttyUSB0"))
		_on_Baudoption_pressed()
		_on_Baudoption_item_selected(SerialTransceiverProtocol.baudrates.find(115200))
	


func _on_ChangeStateButton_pressed():
	SerialTransceiverProtocol.requestNextStage()

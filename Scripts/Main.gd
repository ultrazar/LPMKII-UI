extends Node


onready var NodePortList = $Main/Panel/Top_options/SerialThings/Port
onready var NodeBaudrateList = $Main/Panel/Top_options/SerialThings/Baudoption

func _ready():
	SerialTransceiverProtocol.setMissionPhase(SerialTransceiverProtocol.PHASE_AIR)

func _enter_tree():
	SerialTransceiverProtocol.set_connected(false)

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
	print(NodePortList.get_item_text(index))


func _on_Baudoption_item_selected(index):
	SerialTransceiverProtocol.SelectBaudrate(NodeBaudrateList.get_item_text(index))
	print(NodeBaudrateList.get_item_index(index))


func _on_reloadFilesButton_pressed():
	SerialTransceiverProtocol.sendLine("/L")

var fileToDownload = ""
var fileToDownloadSize

const downloadConfirmationDialogText = \
"""Are you sure to download %s file? (%s bytes)
It will take %s seconds approximately...
"""

func _on_ItemList_item_activated(index):
	fileToDownload = $Main/Middle/TabContainer/Images/ItemList.get_item_text(index).split(" ")[0]
	fileToDownloadSize = SerialTransceiverProtocol.files[fileToDownload][0]
	$ConfirmationDialog.dialog_text = downloadConfirmationDialogText % [fileToDownload,str(fileToDownloadSize),str(fileToDownloadSize / 2400)]
	$ConfirmationDialog.popup()


func _on_ConfirmationDialog_confirmed():
	SerialTransceiverProtocol.downloadFile(fileToDownload)

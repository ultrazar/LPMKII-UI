extends Node


onready var NodePortList = $Main/Panel/Top_options/SerialThings/Port
onready var NodeBaudrateList = $Main/Panel/Top_options/SerialThings/Baudoption


func _on_Port_pressed():
	NodePortList.clear()
	for item in SerialTransceiverProtocol.GetPortsList():
		NodePortList.add_item(str(item))
	


func _on_Baudoption_pressed():
	NodeBaudrateList.clear()
	for item in SerialTransceiverProtocol.GetBaudrates():
		NodeBaudrateList.add_item(str(item))

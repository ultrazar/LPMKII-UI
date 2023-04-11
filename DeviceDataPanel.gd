extends VBoxContainer


func _process(delta):
	var data = SerialTransceiverProtocol.LPMKII_DATA
	$Battery/Label.text = "Battery: %sV" % str(data["lipo_voltage"])
	$Battery/ProgressBar.value = data["lipo_voltage"]
	$SolarPanels/Label.text = "Solar panels: %sV" % "0" # TODO
	$SolarPanels/ProgressBar.value = 0
	$GPS/Coordinates.text = "%s,%s" % [str(data["latitude"]),str(data["longitude"])]

func _on_GPS_CheckBox_pressed():
	$GPS/Coordinates.visible = not $GPS/Coordinates.visible

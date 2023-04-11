extends VBoxContainer

var legsOpened = 2

func sendParams(param=null):
	SerialTransceiverProtocol.sendSystemParams(
		legsOpened,
		$CameraPanel/HBoxContainer/VBoxContainer/ServoParameter/HSlider.value,
		$Localization/HBoxContainer/VBoxContainer/Buzzer/CheckButton.pressed,
		$Localization/HBoxContainer/VBoxContainer/LED/CheckButton.pressed,
		$Localization/HBoxContainer/VBoxContainer/GPS/CheckButton.pressed,
		$Transceiver/HBoxContainer/VBoxContainer/Frequency/OptionButton.selected,
		$Transceiver/HBoxContainer/VBoxContainer/TransmissionPower/OptionButton.selected
	)

func updateLegsPanel():
	match SessionData.legsState:
		SessionData.LEGS_CLOSED:
			$LegsPanel/VBoxContainer/Label.text = "LEGS STATE: CLOSED"
			$LegsPanel/VBoxContainer/LegsButton.disabled = false
			$LegsPanel/VBoxContainer/LegsButton.text = "OPEN LEGS"
			$LegsPanel/VBoxContainer/LegsButton.modulate = Color("ff6464")
		SessionData.LEGS_CLOSING:
			$LegsPanel/VBoxContainer/Label.text = "LEGS STATE: CLOSING"
			$LegsPanel/VBoxContainer/LegsButton.text = "ABORT"
			#$LegsPanel/VBoxContainer/LegsButton.disabled = true
		SessionData.LEGS_OPENING:
			$LegsPanel/VBoxContainer/Label.text = "LEGS STATE: OPENING"
			$LegsPanel/VBoxContainer/LegsButton.text = "ABORT"
			#$LegsPanel/VBoxContainer/LegsButton.disabled = true
		SessionData.LEGS_OPENED:
			$LegsPanel/VBoxContainer/Label.text = "LEGS STATE: OPENED"
			$LegsPanel/VBoxContainer/LegsButton.disabled = false
			$LegsPanel/VBoxContainer/LegsButton.text = "CLOSE LEGS"
			$LegsPanel/VBoxContainer/LegsButton.modulate = Color("64ff79")

func _on_LegsButton_pressed():
	$LegsTimer.start()
	if (SessionData.legsState == SessionData.LEGS_OPENED):
		legsOpened = 0
		SessionData.legsState = SessionData.LEGS_CLOSING
	elif (SessionData.legsState == SessionData.LEGS_CLOSED):
		legsOpened = 1
		SessionData.legsState = SessionData.LEGS_OPENING
	elif (SessionData.legsState == SessionData.LEGS_CLOSING):
		SessionData.legsState = SessionData.LEGS_CLOSED
		legsOpened = 2
	elif (SessionData.legsState == SessionData.LEGS_OPENING):
		legsOpened = 2
		SessionData.legsState = SessionData.LEGS_OPENED
	sendParams()
	legsOpened = 2
	updateLegsPanel()


func _on_LegsTimer_timeout():
	if (SessionData.legsState == SessionData.LEGS_OPENING):
		SessionData.legsState = SessionData.LEGS_OPENED
	elif (SessionData.legsState == SessionData.LEGS_CLOSING):
		SessionData.legsState = SessionData.LEGS_CLOSED
	updateLegsPanel()

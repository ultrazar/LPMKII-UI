extends PanelContainer

const imageSizes  = [
	"SIZE_96x96",
	"SIZE_160x120",   
	"SIZE_176x144",   
	"SIZE_240x176",    
	"SIZE_240x240",
	"SIZE_320x240",     
	"SIZE_400x296",     
	"SIZE_480x320",     
	"SIZE_640x480",      
	"SIZE_800x600",     
	"SIZE_1024x768",      
	"SIZE_1280x720",       
	"SIZE_1280x1024",     
	"SIZE_1600x1200"
];

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in imageSizes:
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I1ImageSize/OptionButton.add_item(i)
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I2ImageSize/OptionButton.add_item(i)
	$HBoxContainer/VBoxContainer/CameraIntervalParameters/I1ImageSize/OptionButton.select(11)
	$HBoxContainer/VBoxContainer/CameraIntervalParameters/I2ImageSize/OptionButton.select(8)

func _on_CheckButton_pressed(): # Camera interval button
	$HBoxContainer/VBoxContainer/CameraIntervalParameters.visible = not $HBoxContainer/VBoxContainer/CameraIntervalParameters.visible


func _on_SendSettingsButton_pressed():
	SerialTransceiverProtocol.sendCameraSettings(
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I1CaptureRate/SpinBox.value if $HBoxContainer/VBoxContainer/EnableCamera/CheckButton.pressed else 3600,
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I2CaptureRate/SpinBox.value if $HBoxContainer/VBoxContainer/EnableCamera/CheckButton.pressed else 3600,
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I1ImageSize/OptionButton.selected,
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I2ImageSize/OptionButton.selected,
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I1Compression/Slider.value,
		$HBoxContainer/VBoxContainer/CameraIntervalParameters/I2Compression/Slider.value
	)

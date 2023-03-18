extends Control

const SERCOMM = preload("res://bin/GDsercomm.gdns")
onready var PORT = SERCOMM.new()

#helper node
onready var com=$Com 
#use it as node since script alone won't have the editor help

var port



func _ready():
	#adding the baudrates options
	$OptionButton.add_item("")
	for index in com.baud_list: #first use of com helper
		$OptionButton.add_item(str(index))


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
	"lipo_voltage":0.0
}
var buffer = ""

func update_vars(hex):
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


func _physics_process(delta): 
	if PORT.get_available()>0:
		for i in range(PORT.get_available()):
			var actual = PoolByteArray([PORT.read(true)]).hex_encode()
			buffer += actual
			var spl = buffer.split("12345678")
			if len(spl) == 2:
				if spl[0] != "":
					print(spl[0].length())
					update_vars(spl[0])
				
				$RichTextLabel.text = spl[0]
				buffer = spl[1]
				
				$RichTextLabel.text += "\n" + JSON.print(LPMKII_DATA,"\t")




				
func _on_SendButton_pressed():
	send_text()

func _on_OptionButton_item_selected(ID):
	set_physics_process(false)
	PORT.close()
	if port!=null and ID!=0:
		PORT.open(port,int($OptionButton.get_item_text(ID)),1000)
	else:
		print("You must select a port first")
	set_physics_process(true)

func _on_UpdateButton_pressed(): #Updates the port list
	$PortList.clear()
	$PortList.add_item("Select Port")
	for index in PORT.list_ports():
		$PortList.add_item(str(index))

func _on_PortList_item_selected(ID):
	port=$PortList.get_item_text(ID)
	$OptionButton.select(0)

func _on_LineEdit_gui_input(ev):
	if ev is InputEventKey and ev.scancode==KEY_ENTER:
		if($LineEdit.text!=""): #due to is_echo not working for some reason
			send_text()

func send_text():
	#LineEdit does not recognize endline
	var text=$LineEdit.text.replace(("\\n"),com.endline)

	if $CheckBox.pressed: #if checkbox is active, add endline
		text+=com.endline

	PORT.write(text) #write function, please use only ascii
	$LineEdit.text=""

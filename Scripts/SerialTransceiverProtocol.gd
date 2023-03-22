extends Node
# SerialTransceiverProtocol - Singleton (Global variable)
# Manages the serial communication for the Transceiver and the LPMKII protocol


const SERCOMM = preload("res://bin/GDsercomm.gdns")
onready var PORT = SERCOMM.new()

const baudrates = [300,600,1200,2400,4800,9600,14400,19200,28800,38400,57600,115200]
var port

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
				buffer = spl[1]


func GetBaudrates():
	return baudrates

func SelectBaudrate(baudrate):
	set_physics_process(false)
	PORT.close()
	if port!=null and baudrate!=0:
		PORT.open(port,baudrate,1000)
	else:
		breakpoint
	set_physics_process(true)

func GetPortsList(): #Updates the port list
	return PORT.list_ports()

func SelectPort(PortName):
	port=PortName

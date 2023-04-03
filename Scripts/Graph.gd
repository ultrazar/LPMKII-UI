extends VBoxContainer

# docs: https://github.com/fenix-hub/godot-engine.easy-charts

const UPDATE_TIME = 0.5 # in seconds

onready var chart: Chart = $Chart
onready var ParametersPanel = $Panel/HBoxContainer
onready var GraphSensorParameter = preload("res://Nodes/GraphSensorParameter.tscn")

# This Chart will plot 3 different functions
var f1: Function
var f2: Function
var f3: Function

const GraphParametersList = {
	"temperature":null,
	"pressure":null,
	"humidity":null,
	"GPS_altitude":null
}

var FunctionsDict = {
}

var cp: ChartProperties = ChartProperties.new()

func reloadFunctions():
	for i in GraphParametersList:
		FunctionsDict[i] = Function.new(
		[], [], i, { 
			color = GraphParametersList[i].get_node("ColorPicker").color, 
			marker = Function.Marker.NONE, 
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.LINEAR
		})
	reloadFunctionsColors()

func reloadFunctionsColors():
	for i in FunctionsDict:
		FunctionsDict[i].props.color = GraphParametersList[i].get_node("ColorPicker").color

func _ready():
	for i in GraphParametersList:
		var instance = GraphSensorParameter.instance()
		GraphParametersList[i] = instance
		instance.get_node("HBoxContainer/Label").text = i
		instance.get_node("ColorPicker").color = Color8(randi() % 255,randi() % 255,randi() % 255)
		ParametersPanel.add_child(instance)
		instance.get_node("HBoxContainer/CheckBox").connect("pressed",self,"reloadGraph")
		instance.get_node("ColorPicker").connect("color_changed",self,"reloadFunctionsColors")
		
	$Timer.wait_time = UPDATE_TIME
	reloadFunctions()
	# Let's customize the chart properties, which specify how the chart
	# should look, plus some additional elements like labels, the scale, etc...

	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.transparent
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.whitesmoke
	cp.draw_bounding_box = false
	cp.title = "Air Quality Monitoring"
	cp.x_label = "Time"
	cp.y_label = "Sensor values"
	cp.x_scale = 5
	cp.y_scale = 10
	cp.interactive = true # false by default, it allows the chart to create a tooltip to show point values
	# and interecept clicks on the plot
	chart.plot([Function.new([0],[100],"null",{}) ], cp)
	

const graphTemplateScene = preload("res://Scenes/Chart.tscn")

func reloadGraph():
	var shownFunctions = []
	
	for i in GraphParametersList:
		if (GraphParametersList[i].get_node("HBoxContainer/CheckBox").pressed):
			shownFunctions.append(FunctionsDict[i])
	
	if shownFunctions.size() != 0:
		remove_child($Chart)
		var newInstance = graphTemplateScene.instance()
		add_child(newInstance)
		

		newInstance.plot(shownFunctions,cp)
		chart = newInstance

var time = 0

var plotted = false

func _on_Timer_timeout():
	for i in GraphParametersList:
		FunctionsDict[i].add_point(time,SerialTransceiverProtocol.LPMKII_DATA[i])
		GraphParametersList[i].get_node("HBoxContainer/Data").text = str(SerialTransceiverProtocol.LPMKII_DATA[i])
	
	time += UPDATE_TIME
	
	if (not plotted):
		plotted = true
		reloadGraph()
	
	chart.update() # This will force the Chart to be updated


func _on_ClearButton_pressed():
	reloadFunctions()
	time = 0
	plotted = false

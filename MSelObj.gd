extends Control
signal button_pressed(destination,episode)

onready var title = $Title
onready var desc = $Description
onready var buttons = $HBoxContainer

var thisEpisode:Globals.Episode
var partDestinations:Array

func _ready():
	for i in range(buttons.get_child_count()):
		buttons.get_child(i).connect("pressed",self,"buttonTrigger",[i])
#	setNumParts2(["Test 1","Test 2","Test 3","test1.txt","test2.txt","test3.txt"])

func setEpisode(episode:Globals.Episode):
	thisEpisode=episode
	if INITrans.HasString("ChapterParts",episode.title):
		var s = INITrans.GetString("ChapterParts",episode.title,false).split("\t",true,1)
		title.text=s[0]
		desc.text=s[1]
	else:
		title.text=episode.title
		desc.text=episode.desc
	setNumParts(episode.parts)

func setNumParts(partDestinations_:Array):
	self.partDestinations=partDestinations_
	var length = partDestinations.size()
	for i in range(buttons.get_child_count()):
		var button = buttons.get_child(i)
		if i < length:
			button.visible=true
			button.get_child(0).text="Part "+String(i+1)
		else:
			button.visible=false

##Not necessary right now
#func setNumParts2(partNamesAndDestinations:Array):
#	var length:int = partNamesAndDestinations.size()
#	partDestinations.resize(length/2)
#	for i in range(length/2):
#		buttons.get_child(i).get_child(0).text=partNamesAndDestinations[i]
#		partDestinations[i]=partNamesAndDestinations[i+length/2]
#
#	#for i in range(length/2,length):
#	#	partDestinations

func buttonTrigger(b:int):
	if b > partDestinations.size()-1:
		printerr("Pressed a button that shouldn't be pressable")
		return
	print(String(b)+" was pressed! Destination is "+partDestinations[b])
	emit_signal("button_pressed",partDestinations[b],thisEpisode)

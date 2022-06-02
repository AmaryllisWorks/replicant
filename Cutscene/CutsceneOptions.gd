extends Control
signal options_closed()

const MAX_OPTION_NAME_WIDTH=600
const MAX_VALUE_WIDTH=450
const MENU_LEFT_PADDING=40

var options = {
	"continue":{
		type="none",
		hasFunc=true
	},
	"skip":{
		type="none",
		hasFunc=true
	},
	"textSpeed":Globals.OPTIONS['textSpeed'],
	"skipMode":Globals.OPTIONS['skipMode'],
	#"testOption":Globals.OPTIONS['testOption'],
	#"language":Globals.OPTIONS['language'],
	"systemOptions":{
		type="submenu",
		submenu="systemOptionsSubmenu"
	},
	"chapterSelect":{
		type="none",
		hasFunc=true
	}
}
func action_chapterSelect():
	t.stop_all()
	t.interpolate_property($ScreenOut,"color:a",null,1.0,.5)
	t.start()
	#t.connect("tween_completed",self,"screenOut2")
	yield(t,"tween_completed")
	
	if anyOptionWasChanged:
		Globals.save_system_data()
		anyOptionWasChanged=false
	get_tree().change_scene("res://TitleScreen.tscn")
#func screenOut2():
#	get_tree().change_scene("res://TitleScreen.tscn")
func action_continue():
	OffCommand()
func action_skip():
	
	if anyOptionWasChanged:
		Globals.save_system_data()
		anyOptionWasChanged=false
	#Godot parent checking isn't really that good so just hard code it
	var root = get_tree().get_root().has_node("CutsceneFromFile")
	if root:
		t.interpolate_property($ScreenOut,"color:a",null,1.0,.5)
		t.start()
		get_tree().get_root().get_node("CutsceneFromFile")._on_CutscenePlayer_cutscene_finished()
	else:
		print("No cutscene player found... Assuming that this is debugging")
	#get_parent().end_cutscene()

var font = preload("res://Fonts/OptionsFont.tres")
#var displayedOptions:int=0
onready var desc = $DescrptionF/Description
onready var selectSound = $AudioStreamPlayer

#How not to program
var selection:int = 0
var subMenuSelection:int=0
var isSubMenu:bool=false
var optionsFrame:Control #created on _init()
var systemOptionsSubmenu:Control

var anyOptionWasChanged:bool=false


onready var arrowTween = $ArrowTween
func highlightList(optFrame:Control,curSel:int):
	arrowTween.stop_all()
	for node in optFrame.get_children():
		var isSelected=(node.name == "Item"+str(curSel))
		if isSelected:
			node.set("modulate", Color(1,1,1,1));
		else:
			node.set("modulate", Color(.5,.5,.5,1));
			
		if node.has_node("BoolOn"):
			var opt = node.get_meta("opt_name")
			#print(opt)
			highlightBool(node,Globals.OPTIONS[opt]['value'])
		elif node.has_node("Value"):
			if isSelected:
				#node.get_node("animPlayer").play("arrow")
				pass
			else:
				#node.get_node("animPlayer").stop(true)
				
				var lArrow = node.get_node("leftArrow")
				var rArrow = node.get_node("rightArrow")
				arrowTween.interpolate_property(lArrow,"rect_position:x",null,800-64*2,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
				arrowTween.interpolate_property(rArrow,"rect_position:x",null,800+MAX_VALUE_WIDTH,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
				#lArrow.rect_position.x=800-64*2
				#rArrow.rect_position.x=800+MAX_VALUE_WIDTH
	arrowTween.start()
	if curSel!=-1:
		desc.text=INITrans.GetString("OptionDescriptions",optFrame.get_child(curSel).get_meta("opt_name"))
		update_desc_size()
	
func highlightBool(node,b):
	node.get_node("BoolOff").set("modulate", Color(.5,.5,.5,1) if b else Color(1,1,1,1));
	node.get_node("BoolOn").set("modulate", Color(.5,.5,.5,1) if not b else Color(1,1,1,1));

func update_desc_size():
	var width = get_viewport().get_visible_rect().size.x-50
	#print(desc.text)
	
	var width2 = desc.get("custom_fonts/font").get_string_size(desc.text).x
	if width2 > width:
		desc.rect_scale.x=width/width2
		desc.rect_position.x=25*width/width2
		desc.rect_size.x=width2 #For some hilarious reason this doesn't update on its own until the next frame, so do it ourselves.
	else:
		desc.rect_scale.x=1.0
		desc.rect_position.x=25
		desc.rect_size.x=width
	#print(desc.rect_size.x)
	
func updateValue(o:String,optionHolderNode:Control):
	var valNode = optionHolderNode.get_node("Value")
	if optionHolderNode.get_meta("opt_type")=="list":
		var text = String(Globals.OPTIONS[o]['value'])
		#print(text)
		if 'localizeKey' in Globals.OPTIONS[o]:
			text=INITrans.GetString(Globals.OPTIONS[o]['localizeKey'],text)
		#
		var width2 = font.get_string_size(text).x
		valNode.text=text
		#Godot is funny and setting text will cause the rect_size to be updated...
		#in the next idle frame. That means that the rect gets resized AFTER we
		#set it unless we wait 1 frame. Very stupid, but whatever.
		#set_deferred() also does not work for these properties for some reason.
		yield(get_tree(), "idle_frame")
		if width2 > MAX_VALUE_WIDTH:
			valNode.rect_size.x=width2
			var scaling = MAX_VALUE_WIDTH/width2
			valNode.rect_scale.x=scaling
			#valNode.set_deferred("rect_scale:x",scaling)
			#print("Calculated width of "+String(width2)+" for str "+text)
			valNode.rect_position.x=800
			#valNode.rect_position.x=800*scaling
			#valNode.rect_size.x=width2
		else:
			#print("NoRescale")
			#valNode.set_deferred("rect_scale:x",1.0)
			valNode.rect_scale.x=1.0
			valNode.rect_position.x=800
			#valNode.rect_size.x=0
			valNode.rect_size.x=MAX_VALUE_WIDTH
		#yield(get_tree(), "idle_frame")
		#print("Scale to "+String(valNode.rect_scale.x)+", dest size is "+String(450.0*valNode.rect_scale.x))
		#print(valNode.rect_position.x)
		#print(valNode.rect_size.x)
			#valNode.rect_size.x=MAX_VALUE_WIDTH
		#print("Set new text "+text)
		#print(valNode.text)
	else:
		valNode.text=String(Globals.OPTIONS[o]['value'])
		#int types never exceed the max text width so this isn't necessary
		#valNode.rect_scale.x=1.0
		#valNode.rect_position.x=800
		#Because min_width was removed... This shouldn't be here
		valNode.rect_size.x=MAX_VALUE_WIDTH

func updateTranslation(refresh:bool=false):
	for f in [optionsFrame,systemOptionsSubmenu]:
		for node in f.get_children():
			if node.has_meta("opt_name"):
				var o = node.get_meta("opt_name")
				var tn = node.get_node("TextActor")
				tn.text=INITrans.GetString("Options",o)
				var width = font.get_string_size(tn.text).x
				if width > MAX_OPTION_NAME_WIDTH:
					var scaling = MAX_OPTION_NAME_WIDTH/width
					tn.rect_scale.x=scaling
				else:
					tn.rect_scale.x=1.0
				
				if node.has_node("Value"):
					updateValue(o,node)
#				#print(width)
			#for nn in node.get_children():
			#	if nn is Label:
			#		nn.set("custom_fonts/font",INITrans.font)
	#desc.text=INITrans.GetString("OptionDescriptions",optFrame.get_child(curSel).get_meta("opt_name"))
	#update_desc_size()

#Fuck your return oriented programming
var arrowSprite = preload("res://Ext/other_329.png")
func generateMenu(optFrameActor:Control,optionsDict:Dictionary,arrowAnimation:Animation):
	var i = 0
	for option in optionsDict:
		
		var optionItem = Control.new()
		optionItem.name="Item"+str(i)
		optionItem.set_meta("opt_name",option)
		optionItem.set_meta("opt_type",optionsDict[option]['type'])
		optionItem.rect_position=Vector2(0,i*110)
		optionItem.modulate.a=0
		var optionNameActor = Def.LoadFont(font,{
			"name":"TextActor",
			"text":option,
			"uppercase":false,
			mouse_filter=MOUSE_FILTER_IGNORE
		})
		#optionNameActor.connect("mouse_entered",self,"handle_mouse_entered",[i])
		#print(parent.font.get_string_size(option))
		#print(Globals.OPTIONS[option])
		match optionsDict[option]['type']:
			"int","list":
				#optionItem.add_child(Def.Quad({
				#	rect_position=Vector2(800,0),
				#	color=Color.black,
				#	size=Vector2(MAX_VALUE_WIDTH,116)
				#}))
				optionItem.add_child(Def.LoadFont(font,{
					name="Value",
					#Cannot be set until _ready()
					#text=Globals.OPTIONS[option]['value'],
					#"uppercase":true,
					rect_position=Vector2(800,0),
					#rect_min_size=Vector2(MAX_VALUE_WIDTH,0),
					align=HALIGN_CENTER,
					mouse_filter=MOUSE_FILTER_IGNORE
				}))
				optionItem.add_child(Def.Sprite({
					name='leftArrow',
					#TextureFromDisk="res://Ext/other_329.png",
					rect_position=Vector2(800-64*2,116/2-64),
					rect_scale=Vector2(2,2),
					flip_h=true,
					mouse_filter=MOUSE_FILTER_STOP
				}))
				optionItem.add_child(Def.Sprite({
					name='rightArrow',
					#TextureFromDisk="res://Ext/other_329.png",
					rect_position=Vector2(800+MAX_VALUE_WIDTH,116/2-64),
					rect_scale=Vector2(2,2),
					mouse_filter=MOUSE_FILTER_STOP
				}))
				optionItem.get_child(1).texture=arrowSprite
				optionItem.get_child(2).texture=arrowSprite
				var animationPlayer=AnimationPlayer.new()
				animationPlayer.name="animPlayer"
				animationPlayer.add_animation("arrow",arrowAnimation)
				#animationPlayer.autoplay="arrow"
				optionItem.add_child(animationPlayer)
				
				optionItem.get_child(1).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,false])
				optionItem.get_child(2).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,true])

			"bool":
				optionItem.add_child(Def.LoadFont(font,{
					"name":"BoolOff",
					"text":"Off",
					"rect_position":Vector2(800,0),
					rect_min_size=Vector2(MAX_VALUE_WIDTH/2.0,0),
					"uppercase":true,
					align=1,
					mouse_filter=MOUSE_FILTER_STOP
				}))
				optionItem.add_child(Def.LoadFont(font,{
					"name":"BoolOn",
					"text":"On",
					"rect_position":Vector2(800+MAX_VALUE_WIDTH/2.0,0),
					rect_min_size=Vector2(MAX_VALUE_WIDTH/2.0,0),
					"uppercase":true,
					align=1,
					mouse_filter=MOUSE_FILTER_STOP
				}))
				#self.connect("draw",)
				optionItem.get_child(0).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,false])
				optionItem.get_child(1).connect("gui_input",self,"handle_mouse_BoolOffOn",[optionItem,true])
			_:
				pass
		
		#displayedOptions+=1
		optionItem.add_child(optionNameActor)
		i=i+1
		
		optFrameActor.add_child(optionItem)
		#optionsList.append(option)
	print("[OptionsMenu] Created new menu with "+String(i)+" options")
	#return optFrameActor

func _init():
	add_child(Def.Quad({
		color=Color(0,0,0,.8),
		rect_size=Vector2(1920,1080),
		anchor_right=1,
		anchor_bottom=1
	}));
	
	#for k in Globals.OPTIONS:
	#	options[k]=Globals.OPTIONS[k]
	#options["chapterSelect"]={
	#	type="none",
	#	hasFunc=false
	#}
	#existing_children=get_child_count()
	
	#GOD WHY
	var animation:Animation = Animation.new()
	animation.loop=true
	animation.length=0.25
	
	var leftArrowAnim = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(leftArrowAnim,"leftArrow:rect_position:x")
	animation.track_set_interpolation_type(leftArrowAnim,Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(leftArrowAnim,0,800-64*2)
	animation.track_insert_key(leftArrowAnim,.25/2,800-64*2-8)
	animation.track_insert_key(leftArrowAnim,.25,800-64*2)
	
	var rightArrowAnim = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rightArrowAnim,"rightArrow:rect_position:x")
	animation.track_set_interpolation_type(rightArrowAnim,Animation.INTERPOLATION_CUBIC)
	animation.track_insert_key(rightArrowAnim,0,800+MAX_VALUE_WIDTH)
	animation.track_insert_key(rightArrowAnim,.25/2,800+MAX_VALUE_WIDTH+8)
	animation.track_insert_key(rightArrowAnim,.25,800+MAX_VALUE_WIDTH)
	
	optionsFrame = Control.new()
	optionsFrame.name="MainMenu"
	optionsFrame.rect_position=Vector2(MENU_LEFT_PADDING,150)
	generateMenu(optionsFrame,options,animation)
	add_child(optionsFrame)
	
	systemOptionsSubmenu = Control.new()
	systemOptionsSubmenu.name="SystemOptionsSubmenu"
	systemOptionsSubmenu.rect_position=Vector2(-999,150)
	systemOptionsSubmenu.modulate.a=0
	var systemOptions:Dictionary={}
	for opt in ["AudioVolume","SFXVolume","language"]:
		systemOptions[opt]=Globals.OPTIONS[opt]
	if OS.has_feature("pc"):
		systemOptions['isFullscreen']=Globals.OPTIONS['isFullscreen']
	else:
		systemOptions['goBack']={
			type="return",
			hasFunc=true
		}
	generateMenu(systemOptionsSubmenu,systemOptions,animation)
	add_child(systemOptionsSubmenu)
	#
	
onready var t = $Tween
func _ready():
	if Globals.currentEpisodeData != null:
		var e = Globals.currentEpisodeData
		var heading:String = e.parentChapter
		#var epNum:int = 99
		#var partNum:int=99
		
		var episodes = Globals.chapterDatabase[e.parentChapter]
		for i in range(episodes.size()):
			if episodes[i].title==e.title:
				heading+="-"+String(i+1)
				if episodes[i].parts.size()>1:
					for j in range(episodes[i].parts.size()):
						if episodes[i].parts[j]==Globals.nextCutscene:
							heading+="-"+String(j+1)
							break
				break
		heading+=": "+e.title
		$EpisodeDisplay/Header.text=heading
		$EpisodeDisplay/Description.text=e.desc
	elif OS.is_debug_build():
		$EpisodeDisplay/Header.text="[DEBUG] No chapter set"
		$EpisodeDisplay/Description.text=""
	else:
		$EpisodeDisplay.visible=false
	
	updateTranslation()
	OnCommand()
	self.connect("resized",self,"update_desc_size")
	#realInitPos=position
	pass


func OnCommand():
	#print("OnCommand!")
	#t.stop_all()
	t.interpolate_property(self,"modulate:a",0.0,1.0,.5)
	#optionsFrame.modulate.a=1.0
	#optionsFrame.rect_position.x=MENU_LEFT_PADDING-50
	highlightList(optionsFrame,selection)
	for i in range(optionsFrame.get_child_count()):
		optionsFrame.get_child(i).modulate.a=0
		t.interpolate_property(optionsFrame.get_child(i),"rect_position:x",
		-300,0,.4,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.05)
		t.interpolate_property(optionsFrame.get_child(i),"modulate:a",
		0,1,.4,Tween.TRANS_QUAD,Tween.EASE_OUT,i*.05)
	t.start()
	
	
#	for n in systemOptionsSubmenu.get_children():
#		#print(n.get_meta("opt_type"))
#		#breakpoint
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_IGNORE
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_IGNORE
	#yield(t,"tween_completed")
	#tweenMainMenuOut()
	pass
	#updateFocus()
func OffCommand():
	if anyOptionWasChanged:
		Globals.save_system_data()
		anyOptionWasChanged=false
	#t.stop_all()
	t.interpolate_property(self,"modulate:a",null,0.0,.5)
	var n = optionsFrame.get_child_count()
	for i in range(n):
		t.interpolate_property(optionsFrame.get_child(i),"rect_position:x",
		null,-300,.4,Tween.TRANS_QUAD,Tween.EASE_IN,(n-i)*.05)
		t.interpolate_property(optionsFrame.get_child(i),"modulate:a",
		null,0,.4,Tween.TRANS_QUAD,Tween.EASE_IN,i*.05)
	t.start()
	yield(t,"tween_completed")
	emit_signal("options_closed")
	#self.visible=false
	pass
#func updateFocus():

func anim_option_value(optNode:Control,going_right:bool):
	selectSound.play()
	if going_right:
		var rArrow = optNode.get_node("rightArrow")
		arrowTween.interpolate_property(rArrow,"rect_position:x",800+MAX_VALUE_WIDTH+16,800+MAX_VALUE_WIDTH,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	else:
		var lArrow = optNode.get_node("leftArrow")
		arrowTween.interpolate_property(lArrow,"rect_position:x",800-64*2-16,800-64*2,.1,Tween.TRANS_CUBIC,Tween.EASE_OUT)
			#lArrow.rect_position.x=800-64*2
			#rArrow.rect_position.x=800+MAX_VALUE_WIDTH
	#print("A")
	arrowTween.start()
	
func handle_option(optNode:Control,going_right:bool=true):
	anyOptionWasChanged=true
	var option:String=optNode.get_meta("opt_name")
	match optNode.get_meta("opt_type"):
		"bool":
			Globals.OPTIONS[option]['value']=going_right
			selectSound.play()
			highlightBool(optNode,going_right)
			if option=="isFullscreen":
				Globals.set_fullscreen(going_right)
			print("[OptionsScreen] Set option "+option+" to "+String(Globals.OPTIONS[option]['value']))
		"int":
			var val:int = int(Globals.OPTIONS[option]['value'])
			print("got value "+String(val))
			if going_right:
				if val < 100:
					val+=10
					Globals.OPTIONS[option]['value']=val
					optNode.get_node("Value").text=String(val)
					if option=="AudioVolume" or option=="SFXVolume" or option=="VoiceVolume":
						#if parent.reinaAudioPlayer.nsf_player != null:
						#	var realVolumeLevel = Globals.OPTIONS['AudioVolume']['value']*.6-60
						#	parent.reinaAudioPlayer.nsf_player.set_volume(realVolumeLevel);
						Globals.set_audio_levels()
					anim_option_value(optNode,going_right)
			elif val > 0:
				val-=10
				Globals.OPTIONS[option]['value']=val
				optNode.get_node("Value").text=String(val)
				if option=="AudioVolume" or option=="SFXVolume" or option=="VoiceVolume":
					Globals.set_audio_levels()
				anim_option_value(optNode,going_right)
		"list":
			var val = Globals.OPTIONS[option]['value']
			var idx = Globals.OPTIONS[option]['choices'].find(val,0)
			#print("[OptionsMenu] found value at idx "+String(idx))
			if idx==-1:
				print("[OptionsMenu] could not find value "+String(val)+" in list")
				print(typeof(val))
				print(Globals.OPTIONS[option]['choices'])
			if going_right:
				if idx < len(Globals.OPTIONS[option]['choices'])-1:
					Globals.OPTIONS[option]['value']=Globals.OPTIONS[option]['choices'][idx+1]
					if option=="language":
						INITrans.SetLanguage(Globals.OPTIONS[option]['value'])
						updateTranslation(true)
						desc.text=INITrans.GetString("OptionDescriptions",option)
						update_desc_size()
					print("[OptionsMenu] Set option "+option+" to "+String(Globals.OPTIONS[option]['value']))
					updateValue(option,optNode)
					anim_option_value(optNode,going_right)
			elif idx > 0:
				Globals.OPTIONS[option]['value']=Globals.OPTIONS[option]['choices'][idx-1]
				if option=="language":
					INITrans.SetLanguage(Globals.OPTIONS[option]['value'])
					desc.text=INITrans.GetString("OptionDescriptions",option)
					updateTranslation(true)
					update_desc_size()
				print("[OptionsMenu] Set option "+option+" to "+String(Globals.OPTIONS[option]['value']))
				updateValue(option,optNode)
				anim_option_value(optNode,going_right)



func _input(event):
	if not visible:
		return
	var menuSize:int=0
	var curSel=selection
	var curMenu=optionsFrame
	if isSubMenu:
		curSel=subMenuSelection
		menuSize=systemOptionsSubmenu.get_child_count()
		curMenu=systemOptionsSubmenu
	else:
		menuSize=optionsFrame.get_child_count()
	
	if Input.is_action_pressed("ui_down"):
		if curSel < menuSize-1:
			curSel+=1
		else: #If at bottom, loop to top
			curSel=0
		highlightList(curMenu,curSel)
		#if selection > 5:
		#	moveListUp()
		selectSound.play()
	elif Input.is_action_pressed("ui_up"):
		if curSel > 0:
			curSel-=1
		else: #if selection is -1 or at top, loop to bottom
			curSel=menuSize-1
		highlightList(curMenu,curSel)
		#if selection < 6:
		#	moveListDown()
		selectSound.play()
	elif Input.is_action_pressed("ui_left"):
		if curSel==-1:
			return
		var option = curMenu.get_child(curSel)
		handle_option(option,false)
		get_tree().set_input_as_handled()
	elif Input.is_action_pressed("ui_right"):
		if curSel==-1:
			return
		var option = curMenu.get_child(curSel)
		handle_option(option)
		get_tree().set_input_as_handled()
	elif Input.is_action_pressed("ui_select") or (event is InputEventMouseButton and event.button_index==1 and event.pressed):
		
		if event is InputEventMouseButton:
			curSel=get_selection_from_mouse_pos(curMenu,event)
			#Do not handle input if the mouse is in the 'value' side
			if event.position.x > curMenu.rect_global_position.x+MAX_OPTION_NAME_WIDTH:
				#if curSel!=-1:
				#	var curOpt = curMenu.get_child(curSel)
				#	var hasArrows = curOpt.get_meta("opt_type")
				#	if event.position.x > curOpt.
				#	handle_option(curOpt,onOrOff)
				#	get_tree().set_input_as_handled()
				return
			get_tree().set_input_as_handled()
			
		if curSel!=-1:
			var curOpt = curMenu.get_child(curSel)
			var optName = curOpt.get_meta("opt_name")
			match curOpt.get_meta("opt_type"):
				"submenu":
					highlightList(systemOptionsSubmenu,subMenuSelection)
					tweenMainMenuOut();
					isSubMenu=true
					return
				"none":
					if optName in options and options[optName]['hasFunc']:
						call("action_"+optName)
	elif Input.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index==2 and event.pressed):
		if t.is_active(): #Because right clicking opens the options menu and this doesn't take into account that it's been handled...
			return
		if isSubMenu:
			tweenMainMenuIn();
			highlightList(optionsFrame,selection) #This just updates the description
			isSubMenu=false
			return
		else:
			OffCommand()
	elif event is InputEventMouseMotion:
		var tmpSel=get_selection_from_mouse_pos(curMenu,event)
		if tmpSel!=curSel:
			highlightList(curMenu,tmpSel)
			curSel=tmpSel
	#elif :
	#	curSel=get_selection_from_mouse_pos(curMenu,event)
		
		#highlightList(curMenu,curSel)
	if isSubMenu:
		#print("update submenu sel")
		subMenuSelection=curSel
	else:
		selection=curSel
	#elif Input.is_action_pressed("ui_start"):
	#	pass
func handle_input_accept():
	print("Clicked")
	pass

func handle_mouse_BoolOffOn(event:InputEvent,optionItem:Control,onOrOff:bool):
	#OptionItems don't know if they're visible or not, so check if the menu
	#is currently active
	if (event is InputEventMouseButton and event.button_index==1 and event.pressed): #
		print("[OptionsMenu] Clicked item "+optionItem.get_meta("opt_name"))
		if optionItem.get_parent().modulate.a<.9:
			print("[OptionsMenu] menu not visible, ignore...")
			return
		#print(optionItem.get_parent().name)
		#print(optionItem.get_parent().modulate)
		#breakpoint
		#var curMenu=optionsFrame
		#if isSubMenu:
		#	curMenu=systemOptionsSubmenu
		#var option = curMenu.get_child(selection)
		handle_option(optionItem,onOrOff)
		get_tree().set_input_as_handled()

func get_selection_from_mouse_pos(menuToCheck:Control,event:InputEvent)->int:
	#Good luck. You're going to need it.
	var curSel=-1
	for i in range(menuToCheck.get_child_count()):
		
		var actor = menuToCheck.get_child(i)
		if actor.rect_global_position.y < event.position.y and event.position.y < actor.rect_global_position.y+105:
			#print("Guessed? "+String(i))
			curSel = i
			break
	return curSel

func handle_mouse_entered(selection_:int):
	print(selection_)
	selection=selection_
	
	var curMenu=optionsFrame
	if isSubMenu:
		curMenu=systemOptionsSubmenu
	highlightList(curMenu,selection)

func tweenMainMenuOut():
	#TODO: Remove this shit and replace it with the newer tweens
	
	#First tween out main menu
	var tween = $Tween;
	tween.interpolate_property(optionsFrame, 'rect_position:x',
	null, MENU_LEFT_PADDING-200, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(optionsFrame, 'modulate',
	null, Color(1,1,1,0), .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	
	#Tween in the submenu
	var property = "rect_position:x"
	
	var subList = systemOptionsSubmenu;
	tween.interpolate_property(subList, property,
	MENU_LEFT_PADDING+200,
	MENU_LEFT_PADDING,
	.25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(subList, 'modulate:a',
	null, 1.0, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.start();
	#yield(tween,"tween_completed")
	#breakpoint
	
	
#	#Godot, in its infinite wisdom, makes it so pass goes UP, not DOWN
#	#Meaning the language button will cover the main menu text button
#	#So we have to set MOUSE_FILTER to ignore when tweening the menu out
#	for n in systemOptionsSubmenu.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_STOP
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_STOP
#	for n in optionsFrame.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_IGNORE
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_IGNORE


func tweenMainMenuIn():
	
	#Tween the main menu back in
	var tween = $Tween;
	tween.interpolate_property(optionsFrame, 'rect_position:x',
	null, MENU_LEFT_PADDING, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(optionsFrame, 'modulate',
	null, Color(1,1,1,1), .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	
	
	#Tween the submenu out
	var property = "rect_position:x"
	tween.interpolate_property(systemOptionsSubmenu, property,
	null,
	MENU_LEFT_PADDING+200,
	.25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.interpolate_property(systemOptionsSubmenu, 'modulate:a',
	null, 0.0, .25, Tween.TRANS_QUAD, Tween.EASE_OUT);
	tween.start();
	
#	#Godot, in its infinite wisdom, makes it so pass goes UP, not DOWN
#	#Meaning the language button will cover the main menu text button
#	#So we have to set MOUSE_FILTER to ignore when tweening the menu out
#	for n in systemOptionsSubmenu.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_IGNORE
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_IGNORE
#	for n in optionsFrame.get_children():
#		match n.get_meta("opt_type"):
#			"list","int":
#				n.get_node("leftArrow" ).mouse_filter=MOUSE_FILTER_STOP
#				n.get_node("rightArrow").mouse_filter=MOUSE_FILTER_STOP

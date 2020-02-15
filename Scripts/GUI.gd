extends Control

class_name GUI

# SetCreatureCreatureMode()
# Emitted when the GUI requests that the keyboard/mouse should be ready to place creatures by clicking.
# TODO rename to SetCreateCreatureMode()
signal SetCreatureCreatureMode

# CreateCreatures(mass, radius, movementForceMag, number)
# Emitted when the GUI requests that some creatures be created.
signal CreateCreatures

# SetFoodSpawnRate(numToCreate, delay)
# Emitted when the GUI requests that the food spawn rate be set.
# 'numToCreate' - the number of food to create each food spawn time
# 'delay' - the number of seconds between food spawn times
signal SetFoodSpawnRate

# Emitted when the GUI requests that the time scale be changed.
# SetTimeScale(value)
signal SetTimeScale

# Emitted when the GUI requests that the world bounds be changed.
# SetWorldBounds(width, height)
signal SetWorldBounds

# SetPaintMode()
# Emitted when the GUI requests that the keyboard/mouse should be ready to paint food.
signal SetPaintFoodMode

# SelectCreature()
# Emitted when the GUI's select creature button has been pressed.
signal SelectCreature

# Called when the node enters the scene tree for the first time.
func _ready():
	# when show gui button is clicked, show or hide gui
	$CheckButton.connect("pressed", self, "OnShowGuiPressed")

	# when create creatures button is clicked, emit signal
	$TabContainer/Creature/Panel/Panel/Button.connect("pressed", self, "OnCreateCreaturesPressed")

	# when update food button is clicked, emit signal
	$TabContainer/World/Panel/Panel/Button.connect("pressed", self, "OnUpdateFoodSpawnRatePressed")

	# when time scale slider is changed, emit signal
	$TabContainer/World/Panel/Panel2/HSlider.connect("value_changed",self,"OnTimeSliderValueChanged")

	# when bounds is changed, emit signal
	$TabContainer/World/Panel/Panel3/Button.connect("pressed",self,"OnUpdateBoundsPressed")

	# when paint food button is clicked, emit signal
	$TabContainer/World/Panel/Panel/Button2.connect("pressed",self,"OnPaintFoodClicked")

	# when create creature button is clicked, emit signal
	$TabContainer/Creature/Panel/Panel2/Button.connect("pressed",self,"OnCreateCreaturePressed")

	# when select creature button is clicked, emit signal
	$TabContainer/Stats/Panel/Panel2/Button.connect("pressed",self,"OnSelectCreaturePressed")

# executed when the create creatures button is pressed, will emit the relavant signal.
func OnCreateCreaturesPressed():
	var massInput = self.get_node("TabContainer/Creature/Panel/Panel/LineEdit");
	var radiusInput = self.get_node("TabContainer/Creature/Panel/Panel/LineEdit2");
	var numberInput = self.get_node("TabContainer/Creature/Panel/Panel/LineEdit3");
	var moveForceInput = self.get_node("TabContainer/Creature/Panel/Panel/LineEdit4");

	if massInput.text == "" || massInput.text == null:
		return
	if radiusInput.text == "" || radiusInput.text == null:
		return
	if numberInput.text == "" || numberInput.text == null:
		return

	var mass = massInput.text.to_float()
	var radius = radiusInput.text.to_float()
	var movementForceMag = moveForceInput.text.to_float()
	var number = int(numberInput.text.to_float())

	self.emit_signal("CreateCreatures", mass, radius, movementForceMag, number)

# executed when the create creature (singular) button is pressed, will emit relavant signal.
func OnCreateCreaturePressed():
	self.emit_signal("SetCreatureCreatureMode")
	


# Executed when the show gui button is toggled; will toggle visibility of the entire gui.
func OnShowGuiPressed():
	var showGuiBtn = self.get_node("CheckButton")
	var controlToHide = self.get_node("TabContainer");

	if showGuiBtn.pressed:
		controlToHide.visible = true;
	else:
		controlToHide.visible = false;

# Executed when the update food spawn rate button is pressed; will emit relavant signal.
func OnUpdateFoodSpawnRatePressed():
	var numToCreateInput = self.get_node("TabContainer/World/Panel/Panel/LineEdit")
	var delayInput = self.get_node("TabContainer/World/Panel/Panel/LineEdit2")
	var numToCreate = numToCreateInput.text.to_int()
	var delay = delayInput.text.to_float()
	self.emit_signal("SetFoodSpawnRate",numToCreate,delay)

# Executed when the time scale slider changes; will emit relavant signal.
func OnTimeSliderValueChanged(value):
	var timeScaleLabel = self.get_node("TabContainer/World/Panel/Panel2/Label2")
	timeScaleLabel.text = str(value) + "x";
	self.emit_signal("SetTimeScale",value)

# Executed when the update bounds button has been pressed; will emit relavant signal.
func OnUpdateBoundsPressed():
	var width = self.get_node("TabContainer/World/Panel/Panel3/LineEdit").text.to_float()
	var height = self.get_node("TabContainer/World/Panel/Panel3/LineEdit2").text.to_float();
	self.emit_signal("SetWorldBounds",width,height)

# Executed when the paint food button is clicked; will emit relavant signal.
func OnPaintFoodClicked():
	self.emit_signal("SetPaintFoodMode")

# Executed when the select creature button is pressed; will emit relavant signal.
func OnSelectCreaturePressed():
	self.emit_signal("SelectCreature");


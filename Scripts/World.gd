extends Spatial

var height = 100.0;
var width = 100.0;

var creatureGenerator : PackedScene
var foodGenerator_ : PackedScene
var foodTimer_ : Timer

var statTimer_ : Timer

# mouse pan
var cameraDragClickPos_ : Vector2 # the screen position that right mouse button was clicked
var cameraDragCamPos_ : Vector3 # the camera's position when right mouse button was clicked
var numFoodPerSpawn = 10 # how many food to spawn each time we decide to spawn food

var creatures = [] # all the creatures spanwed
var foods = [] # all the foods in the world

var selectingCreature_ : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	creatureGenerator = load("res://Scenes/Creature.tscn")

	# create some initial food
	foodGenerator_ = load("res://Scenes/Food.tscn")
	for i in range(20):
		var food = foodGenerator_.instance();
		self.add_child(food);
		self.foods.append(food);
		var randomX = rand_range(0, self.width);
		var randomZ = rand_range(0, self.height);
		food.translation = Vector3(randomX, 0, randomZ);

	# create food timer (spawns food periodically)
	foodTimer_ = Timer.new();
	self.add_child(foodTimer_);
	foodTimer_.wait_time = 1;
	foodTimer_.connect("timeout", self, "OnSpawnFood");
	foodTimer_.start();

	# create stat timer (periodically reclaculates stats)
	statTimer_ = Timer.new()
	self.add_child(statTimer_)
	statTimer_.wait_time = 1;
	statTimer_.connect("timeout", self, "OnCalculateStats");
	statTimer_.start();

	# connect gui
	var gui = self.get_node("GUI")
	gui.connect("CreateCreatures", self, "OnCreateCreatures");

	gui.connect("SetFoodSpawnRate", self, "OnSetFoodSpawnRate");

	gui.connect("SetTimeScale", self, "OnSetTimeScale");

	gui.connect("SetWorldBounds", self, "OnUpdateBounds");

	gui.connect("SetPaintFoodMode", self, "OnSetFoodPaintMode");

	gui.connect("SetCreatureCreatureMode", self, "OnSetCreateCreatureMode");

	gui.connect("SelectCreature", self, "OnSelectCreaturePressed");

	var menu = self.get_node("Menu")
	menu.connect("QuitApp", self, "OnGUIQuit");

	var foodPainter = self.get_node("FoodPainter");
	foodPainter.connect("SpawnFood", self, "OnFoodPainterSpawnFood");

	var creatureSpawner = self.get_node("CreatureSpawner");
	creatureSpawner.connect("SpawnCreature", self, "OnCreateSingleCreature");

func _unhandled_input(event):
	# unhandled mouse button
	if event is InputEventMouseButton:
		var mousePressed = event as InputEventMouseButton
		
		# right button click
		if mousePressed.button_index == BUTTON_RIGHT:
			cameraDragClickPos_ = mousePressed.position;
			cameraDragCamPos_ = get_viewport().get_camera().translation;
			get_tree().set_input_as_handled()
			return;

		# wheel up/down
		var AMOUNT = get_viewport().get_camera().translation.y / 10;
		if mousePressed.button_index == BUTTON_WHEEL_DOWN:
			get_viewport().get_camera().translation += Vector3(0, AMOUNT, 0);
			get_tree().set_input_as_handled();
			return;
		elif mousePressed.button_index == BUTTON_WHEEL_UP:
			get_viewport().get_camera().translation += Vector3(0, -AMOUNT, 0);
			get_tree().set_input_as_handled();
			return;

	# unhandled mouse move
	if event is InputEventMouseMotion:
		var mouseMoved = event as InputEventMouseMotion
		
		# while right button is down
		if mouseMoved.button_mask & BUTTON_MASK_RIGHT == BUTTON_MASK_RIGHT:
			var camera = get_viewport().get_camera();

			var currentMousePos = mouseMoved.position;
			var shiftVector = currentMousePos - cameraDragClickPos_;
			shiftVector /= 10;
			shiftVector *= camera.translation.y / 35;
			shiftVector *= -1;

			camera.translation = cameraDragCamPos_ + Vector3(shiftVector.x, 0, shiftVector.y);

			get_tree().set_input_as_handled();
			return;
			
	# unhandled keyboard
	if event is InputEventKey:
		var keyPressed = event as InputEventKey
		
		# unhandled escape pressed
		if keyPressed.pressed and keyPressed.scancode == KEY_ESCAPE:
			if self.selectingCreature_:
				self.selectingCreature_ = false;
				Input.set_default_cursor_shape()
				self.get_tree().set_input_as_handled();
				return;

			get_tree().set_input_as_handled();
			var menu = self.get_node("Menu");
			menu.visible = true;
			menu.focus_mode = Control.FOCUS_ALL
			menu.grab_focus();

# executed when the "select creature" button was clicked.
func OnSelectCreaturePressed():
	self.selectingCreature_ = true;
	Input.set_default_cursor_shape(Input.CURSOR_CROSS);

func OnCreatureClicked(creature):
	if self.selectingCreature_:
		var panel = self.get_node("GUI").get_node("TabContainer/Stats/Panel/Panel2");

		panel.get_node("Label7").text = str(creature.mass)
		panel.get_node("Label8").text = str(creature.radius)
		panel.get_node("Label9").text = str(creature.movementForceMag)
		panel.get_node("Label10").text = str(creature.numCreaturesEaten)
		panel.get_node("Label11").text = str(creature.numChildrenSpanwed)

		self.selectingCreature_ = false;
		Input.set_default_cursor_shape();

# executed when the create creatures button is clicked.
# will create the creatures specified.
func OnCreateCreatures(mass, radius, movementForceMag, number):
	for i in range(number):
		var creature = creatureGenerator.instance();
		var randX = rand_range(0, self.width);
		var randZ = rand_range(0, self.height);
		var pos = Vector3(randX, 0, randZ);
		creature.translation = pos;
		creature.InitializeCreature(mass, radius, movementForceMag,self);

# executed when it is time to recalculate stats
func OnCalculateStats():
	if self.creatures.size() == 0:
		return;
	
	var panel = self.get_node("GUI").get_node("TabContainer/Stats/Panel/Panel");

	var totalMass = 0;
	var totalRadius = 0;
	var totalMovementForce = 0;

	for creature in self.creatures:
		totalMass += creature.mass;
		totalRadius += creature.radius;
		totalMovementForce += creature.movementForceMag;

	var numberOfCreatures = self.creatures.size();
	var averageMass = totalMass / numberOfCreatures;
	var averageRadius = totalRadius / numberOfCreatures;
	var averageMovementForce = totalMovementForce / numberOfCreatures;

	var FOOD_EXTENTS = 0.5;
	var individualFoodArea = pow(FOOD_EXTENTS * 2, 2);
	var numberOfFood = self.foods.size();
	var foodArea = numberOfFood * individualFoodArea;
	var area = self.width * self.height;
	var foodDensity = foodArea / area;

	panel.get_node("Label5").text = str(averageMass)
	panel.get_node("Label6").text = str(averageRadius)
	panel.get_node("Label7").text = str(averageMovementForce)
	panel.get_node("Label9").text = str(foodDensity * 100) + " %";

# executed each time we decide to spawn some food
func OnSpawnFood():
	for i in range(self.numFoodPerSpawn):
		var food = foodGenerator_.instance();
		self.add_child(food);
		self.foods.append(food);

		var randomX = rand_range(0, self.width);
		var randomZ = rand_range(0, self.height);
		food.translation = Vector3(randomX, 0, randomZ);

func OnSetFoodSpawnRate(numToCreate, delay):
	self.foodTimer_.wait_time = delay;
	self.numFoodPerSpawn = numToCreate;

func OnSetTimeScale(value):
	Engine.time_scale = value;

func OnGUIQuit():
	self.get_tree().quit();

func OnUpdateBounds( width,  height):
	self.width = width;
	self.height = height;

func OnSetFoodPaintMode():
	var foodPainter = self.get_node("FoodPainter");
	foodPainter.On = true;
	var image = load("res://Art/foodCursor.png");
	var imageCenter =  Vector2(image.get_width() / 2, image.get_height() / 2);
	Input.set_custom_mouse_cursor(image, Input.CURSOR_ARROW, imageCenter);

func OnSetCreateCreatureMode():
	var creatureSpawner = self.get_node("CreatureSpawner");
	creatureSpawner.On = true;
	var image = load("res://Art/createCreatureCursor.png");
	var imageCenter =  Vector2(image.get_width() / 2, image.get_height() / 2);
	Input.set_custom_mouse_cursor(image, Input.CURSOR_ARROW, imageCenter);

func OnFoodPainterSpawnFood(pos):
	var food = foodGenerator_.instance();
	food.translation = pos;
	self.add_child(food);
	self.foods.append(food);

func OnCreateSingleCreature(pos):
	var creature = creatureGenerator.instance();

	var createCreaturePanel = self.get_node("GUI").get_node("TabContainer/Creature/Panel/Panel2");
	
	var mass = float(createCreaturePanel.get_node("LineEdit").text)
	var radius = float(createCreaturePanel.get_node("LineEdit2").text)
	var movementForce = float(createCreaturePanel.get_node("LineEdit4").text)
	
	creature.translation = pos;
	
	creature.InitializeCreature(mass, radius, movementForce,self);


func GetCreaturesInRadius(position, radius):
	var results = []
	for creature in self.creatures:
		if position.distance_to(creature.translation) < radius:
			results.append(creature);
	return results;

# Add a Creature to the World.
func AddCreature(creature):
	creatures.append(creature);
	self.add_child(creature);
	creature.connect("CreatureClicked", self, "OnCreatureClicked");

# Remove a Creature from the World.
func RemoveCreature(creature):
	self.creatures.erase(creature);
	creature.disconnect("CreatureClicked",self,"OnCreatureClicked");

# Returns the Ray projecting from the specified screen position.
# The ray is in world space.
# The first item in the returned array is the origin of the ray, the second item is the direction.
func GetRay(screenPos):
	var currentCam = get_viewport().get_camera();
	var origin = currentCam.project_ray_origin(screenPos);
	var direction = currentCam.project_ray_normal(screenPos);
	return [origin,direction]

# Project a screen position onto the world's XZ plane.
func ScreenPosToWorldPos(screenPos):
	var currentCam = get_viewport().get_camera();
	
	var plane = Plane.PLANE_XZ; # XZ plane (XZ plane is at y = 0 by definition)
	var ray = self.GetRay(screenPos);
	var worldPos = plane.intersects_ray(ray[0], ray[1]);
	return worldPos;

# Returns the Creature that is "under" the specified screen position, or null if there isn't one.
# In other words, projects a ray from the screen position and sees which creature it hits.
func GetCreatureAtScreenPos( screenPos):
	var worldPos = self.ScreenPosToWorldPos(screenPos);

	# create a small area at the world pos
	var area = Area.new();
	var collisionShape =  CollisionShape.new();
	var boxShape = BoxShape.new();
	boxShape.extents = Vector3(0.1, 0.1, 0.1);
	collisionShape.shape = boxShape;
	area.add_child(collisionShape);
	self.add_child(area);
	area.translation = worldPos;

	# see if any creature is in this area
	var result = null;
	for item in area.get_overlapping_bodies():
		if item is Creature:
			var creature = item as Creature
			result = creature;

	# delete temp area
	self.remove_child(area);
	area.queue_free();
	return result;

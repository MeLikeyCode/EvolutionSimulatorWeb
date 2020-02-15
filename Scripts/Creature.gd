extends RigidBody

class_name Creature

const Utilities = preload("Utilities.gd")

# CreatureClicked(Creature)
# Emitted when the Creature is clicked.
signal CreatureClicked

var world				# the world that the creature lives in

# main creature attributes
var creature_mass: float		
var movementForceMag: float
var maxEnergy: float
var radius: float

# internal attributes
var currentEnergy: float
var ateAFood := false
var numChildrenSpanwed := 0
var numCreaturesEaten := 0
var replicationTimer_: Timer
var moveTimer_: Timer
var initialized_ := false

# called when the creature receives a mouse event
func _input_event(camera, event, clickPosition, clickNormal, shapeIdx):
	if event is InputEventMouseButton:
		var mouseEvent = event as InputEventMouseButton
		if mouseEvent.pressed and mouseEvent.button_index == BUTTON_LEFT:
			emit_signal("CreatureClicked",self)
			get_tree().set_input_as_handled()

# called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# use some energy to live        
	var ENERGY_BURN_RATE = self.creature_mass;
	currentEnergy -= ENERGY_BURN_RATE * delta;
	if currentEnergy < 0:
		self.DeleteCreature();

# creature initialization function; must be called after a creature is created.
func InitializeCreature(mass, radius, movementForceMag,world):
	if self.initialized_:
		print("ERROR: Creature is already initialized. Can only be initialized once.")
		get_tree().quit()
		
	self.world = world
	self.world.AddCreature(self)

	# calculate/set physical properties
	self.creature_mass = mass
	self.radius = radius
	self.movementForceMag = movementForceMag

	self.maxEnergy = self.creature_mass * 50
	self.currentEnergy = self.maxEnergy

	# make looks match physical properties
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	$MeshInstance.mesh = mesh
	
	var material = SpatialMaterial.new()
	var brightness = (self.creature_mass / 2.0) * 1.0
	material.albedo_color = Color(brightness, brightness, brightness)
	mesh.material = material

	# create timers/connect signals
	replicationTimer_ = Timer.new()
	self.add_child(replicationTimer_)
	replicationTimer_.wait_time = rand_range(7, 10)
	replicationTimer_.connect("timeout", self, "OnReplicationTimerTimeout")
	replicationTimer_.start()

	moveTimer_ = Timer.new()
	self.add_child(moveTimer_)
	moveTimer_.wait_time = 1
	moveTimer_.connect("timeout", self, "OnMoveTimerTimeout")
	moveTimer_.start();

	self.connect("body_entered", self, "OnCollisionWithCreature");
	self.contact_monitor = true;
	self.contacts_reported = 10;

	self.initialized_ = true;

func move_():
	self.linear_velocity = Vector3(0, 0, 0);

	# rotate
	# - if there are bigger creatures (preditors) nearby, rotate to face away from all of them
	# - otherwise, face a random direction
	
	# get a list of nearby bigger creatures
	var nearbyBiggerCreatures = []
	for creature in self.world.GetCreaturesInRadius(self.translation,10):
		if creature.creature_mass > self.creature_mass and creature != self:
			nearbyBiggerCreatures.append(creature)

	# if there are nearby bigger creatures, face away from all of them
	if nearbyBiggerCreatures.size() > 0:
		var creatureVectors = [] # a list of vectors, each going from this creature to a nearby big creature
		for creature in nearbyBiggerCreatures:
			var vector = self.translation - creature.translation
			creatureVectors.append(vector)
		
		var overallMoveVector = Vector3()
		for vector in creatureVectors:
			overallMoveVector += vector;
		overallMoveVector *= -1;

		# look away from all creatures
		self.look_at(self.translation + overallMoveVector, Vector3(0, 1, 0))
	# if there are no nearby bigger creatures, face random direction
	else:
		var rotation = self.rotation.y + deg2rad(rand_range(-40, 40))
		self.rotation = Vector3(self.rotation.x, rotation, self.rotation.z);
	
		# if touching "wall", face towards center
		var touchingHWall = self.translation.x > world.width || self.translation.x < 0
		var touchingVWall = self.translation.z > world.height || self.translation.z < 0;
		if touchingHWall || touchingVWall:
			self.look_at(Vector3(0, 0, 0), Vector3(0, 1, 0))
			self.rotate_y(deg2rad(180)) # rotate 180 degrees since LookAt makes *negative* z face desired point!

		# move forward
		self.apply_central_impulse(self.transform.basis.z.normalized() * movementForceMag);
		var energyCostToMove = pow(movementForceMag, 2); # energy cost to move = impulse applied ** 2
		self.currentEnergy -= energyCostToMove;

# Executed when it is time for the creature to replicate.
func OnReplicationTimerTimeout():
	# if this creature hasn't eaten a single food, do not replicate
	if (!self.ateAFood):
		return;

	# if this creature doesn't have enough energy to give birth, do not replicate
	var costForBaby = self.creature_mass * 15;
	if self.currentEnergy < costForBaby:
		return;

	# replicate
	var creature = self.world.creatureGenerator.instance()

	var offset = self.get_node("CollisionShape").shape.extents.x
	creature.translation = self.translation + Vector3(offset * 3, 0, 0)
	creature.rotation = self.rotation;
	var childMass = Utilities.RandomizeValue(self.creature_mass, 10)
	var childRadius = Utilities.RandomizeValue(self.radius, 10)
	var childMoveForceMag = Utilities.RandomizeValue(self.movementForceMag, 10);
	
	creature.InitializeCreature(childMass, childRadius, childMoveForceMag,self.world);

	self.currentEnergy -= costForBaby;
	self.numChildrenSpanwed += 1;

	

func OnMoveTimerTimeout():
	move_()

# Executed when this creature collides with another.
func OnCollisionWithCreature(otherCreature):
	if typeof(otherCreature) == typeof(self):
		var asCreature = otherCreature as Creature
		if self.creature_mass != asCreature.mass:
			var biggerCreature = self if self.creature_mass > asCreature.mass else asCreature
			var smallerCreature = asCreature if biggerCreature == self else self
			biggerCreature.currentEnergy += smallerCreature.mass * 100
			biggerCreature.numCreaturesEaten += 1;
			self.DeleteCreature();

# Removes the creature from the World and then QueueFrees it.
func DeleteCreature():
	self.world.RemoveCreature(self);
	self.queue_free()

extends Area

class_name Food

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("body_entered", self, "on_collide");

func on_collide(physicsBody):
	if physicsBody is Creature:
		var creature = physicsBody as Creature
		creature.currentEnergy += 100;
		creature.ateAFood = true;
		creature.world.foods.erase(self);
		self.queue_free()

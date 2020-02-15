extends RigidBody

class_name Test

# Called when the node enters the scene tree for the first time.
func _ready():
		self.add_central_force(Vector3(0, 0, -100))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	print(self.linear_velocity);

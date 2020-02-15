extends Node

class_name FoodPainter

# SpawnFood(pos)
# Emitted when the FoodPainter wants to request a food to be spanwed somewhere.
signal SpawnFood

# public attributes
var On := false			# client must turn us on in order for us to start reacting to unhandled mouse events

# internal attributes
var dragCount_ = 0;

func _unhandled_input(event):
	# only respond to events if we are on
	if not self.On:
		return;
	
	# make sure we create some food with just one click (no drag needed)
	if event is InputEventMouseButton:
		var asMousePress = event as InputEventMouseButton
		if asMousePress.pressed and asMousePress.button_index == BUTTON_LEFT:
			# if left mouse is pressed
			self.dragCount_ = 0;
			for i in range(3):
				var worldPos = self.get_parent().ScreenPosToWorldPos(asMousePress.position);
				worldPos += Vector3(rand_range(-10, 10), 0, rand_range(-10, 10))
				self.emit_signal("SpawnFood", worldPos);

			get_tree().set_input_as_handled()
			return;

	# but as long as we are dragging, keep spawning food
	if event is InputEventMouseMotion:
		var asMouseMotion = event as InputEventMouseMotion
		if (asMouseMotion.button_mask & BUTTON_MASK_LEFT) == BUTTON_MASK_LEFT:
			self.dragCount_ += 1;

			if self.dragCount_ % 3 == 0:
				var currentCam = get_viewport().get_camera()
				var dropPlane = Plane.PLANE_XZ

				for i in range(3):
					var worldPos = self.get_parent().ScreenPosToWorldPos(asMouseMotion.position);
					worldPos += Vector3(rand_range(-10, 10), 0, rand_range(-10, 10));
					self.emit_signal("SpawnFood", worldPos);

			get_tree().set_input_as_handled()
			return;

	# detect when escape is pressed, and end this mode
	if event is InputEventKey:
		var asKeyEvent = event as InputEventKey
		if asKeyEvent.pressed and asKeyEvent.scancode == KEY_ESCAPE:
			self.On = false;
			self.dragCount_ = 0;
			Input.set_custom_mouse_cursor(null)
			
			get_tree().set_input_as_handled()
			return

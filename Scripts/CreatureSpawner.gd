extends Node

class_name CreatureSpawner

# SpawnCreature(pos)
# Emitted when the CreatureSpawner wants to request a creature to be spawned somewhere.
signal SpawnCreature

# public attributes
var On := false;

func _unhandled_input(event):
	# if we are on, emit SpawnCreature signals in response to mouse clicks
	if self.On:
		if event is InputEventMouseButton:
			var asMousePress = event as InputEventMouseButton
			if asMousePress.pressed and asMousePress.button_index == BUTTON_LEFT:
				var worldPos = self.get_parent().ScreenPosToWorldPos(asMousePress.position);
				self.emit_signal("SpawnCreature",worldPos);

				get_tree().set_input_as_handled()
				return;

		# if we receive an escape key, turn off
		if event is InputEventKey:
			var asKeyEvent = event as InputEventKey
			if asKeyEvent.pressed and asKeyEvent.scancode == KEY_ESCAPE:
				self.On = false;
				Input.set_custom_mouse_cursor(null)

				get_tree().set_input_as_handled()
				return;

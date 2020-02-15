extends Control

class_name Menu

# QuitApp()
# Emitted when the quit button is pressed.
signal QuitApp

func _gui_input(event):
	if event is InputEventKey:
		var asKeyEvent = event as InputEventKey
		if asKeyEvent.pressed and asKeyEvent.scancode == KEY_ESCAPE:
			self.visible = false;
			self.accept_event();

# Called when the node enters the scene tree for the first time.
func _ready():
	var quitButton = self.get_node("Panel/Button")
	quitButton.connect("pressed",self,"OnQuitPressed")

func OnQuitPressed():
	self.emit_signal("QuitApp");

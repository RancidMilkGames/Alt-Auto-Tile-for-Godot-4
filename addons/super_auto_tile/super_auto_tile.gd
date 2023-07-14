@tool
extends EditorPlugin


func _enter_tree():
	var editor = get_editor_interface()
	
	for c in editor.get_base_control().get_children(true):
		if c.name.contains("map"):
			print("tile")
			
	
#	print(editor.get_base_control().get_children())
#	for c in editor.get_base_control().get_children():
#		if c.name.contains("TextureRegionEditor"):
#			print(c.get_children()[0].get_children())


func _exit_tree():
	# Clean-up of the plugin goes here.
	pass

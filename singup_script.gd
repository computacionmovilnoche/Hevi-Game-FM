extends Control

var API_KEY = "AIzaSyDRP-_vhAL5lphwYRE5VbUCY_rNCTfdo5E"
var base_url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY

@onready var http_request = $HTTPRequest

func _on_button_pressed() -> void:
	var json_data = {
		"email": $VBoxContainer/username.text,
		"password": $VBoxContainer/password.text,
		"returnSecureToken": true
	}
	
	http_request.request(base_url, [], HTTPClient.METHOD_POST, JSON.stringify(json_data))


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_data = body.get_string_from_utf8()
	# Get user data here
	var json_response = JSON.parse_string(response_data)
	
	# If response is ok
	if (response_code == 200):
		#ser authenticated
		print("Auth")
		get_tree().change_scene_to_file("res://Scenes/login.tscn")
	else:
		# Failed to authenticate
		$VBoxContainer/FeedbackText.text = json_response["error"]["message"]


func _on_button_pressed2() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
	pass # Replace with function body.

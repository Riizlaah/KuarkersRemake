extends Button

signal ServerPressed(ip: String, port: int)

var ip: String
var port: int

func _pressed():
	ServerPressed.emit(ip, port)

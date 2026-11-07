extends Node
## Debug-only playtest console. Listens on localhost; each line received is a
## GDScript Expression evaluated with this node as `self`, so the helpers below
## are callable directly: `press("ui_right", 0.5)`, `node("Player").position`.

const PORT := 7777

var _server := TCPServer.new()
var _peers: Array[StreamPeerTCP] = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	_server.listen(PORT, "127.0.0.1")


func _process(_delta: float) -> void:
	while _server.is_connection_available():
		_peers.append(_server.take_connection())
	for peer in _peers.duplicate():
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.erase(peer)
			continue
		if peer.get_available_bytes() > 0:
			_reply(peer, peer.get_utf8_string(peer.get_available_bytes()).strip_edges())


## A command that returns a Signal (`wait`, `press`) is answered once it fires, so
## the caller's next command sees the game after that much play time.
func _reply(peer: StreamPeerTCP, code: String) -> void:
	var reply := _run(code)
	if reply.get("signal") is Signal:
		await reply.signal
		reply = { "ok": true, "result": "done" }
	peer.put_data((JSON.stringify(reply) + "\n").to_utf8_buffer())


func _run(code: String) -> Dictionary:
	var expr := Expression.new()
	if expr.parse(code) != OK:
		return { "ok": false, "error": expr.get_error_text() }
	var result = expr.execute([], self)
	if expr.has_execute_failed():
		return { "ok": false, "error": expr.get_error_text() }
	if result is Signal:
		return { "signal": result }
	return { "ok": true, "result": var_to_str(result) }


func node(path: String) -> Node:
	return get_tree().current_scene.get_node_or_null(path)


## Holds an input action for `seconds`, as if the player pressed it; replies on
## release.
func press(action: String, seconds: float = 0.1) -> Variant:
	if not InputMap.has_action(action):
		return "unknown action: " + action
	Input.action_press(action)
	var timeout := wait(seconds)
	timeout.connect(Input.action_release.bind(action))
	return timeout


## Replies after `seconds` of game time.
func wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds, true, false, true).timeout


func click(x: float, y: float) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = Vector2(x, y)
		event.global_position = event.position
		event.pressed = pressed
		Input.parse_input_event(event)


## Saves the current frame and returns its absolute path. Needs a windowed run
## --headless renders nothing.
func shot(path: String = "user://shot.png") -> String:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return "no image (headless?)"
	image.save_png(path)
	return ProjectSettings.globalize_path(path)


func actions() -> Array:
	return InputMap.get_actions().filter(func(a): return not String(a).begins_with("ui_"))

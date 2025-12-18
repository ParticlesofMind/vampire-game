extends Node

signal hour_changed(hour: int)
signal time_tick(total_minutes: float)

@export var day_duration_seconds: float = 600.0 # 10 minutes per game day
@export var start_hour: float = 8.0

var current_time_minutes: float = 0.0
var _last_emitted_hour: int = -1

func _ready() -> void:
	current_time_minutes = start_hour * 60.0

func _process(delta: float) -> void:
	# Calculate how many in-game minutes pass per real-time second
	# 24 hours * 60 minutes = 1440 minutes per day
	# 1440 / day_duration_seconds = minutes per second
	var minutes_per_second = 1440.0 / day_duration_seconds
	current_time_minutes += minutes_per_second * delta

	if current_time_minutes >= 1440.0:
		current_time_minutes -= 1440.0

	var current_hour = int(current_time_minutes / 60.0)

	time_tick.emit(current_time_minutes)

	if current_hour != _last_emitted_hour:
		_last_emitted_hour = current_hour
		hour_changed.emit(current_hour)

func get_hour() -> int:
	return int(current_time_minutes / 60.0)

func get_time_string() -> String:
	var h = int(current_time_minutes / 60.0)
	var m = int(current_time_minutes) % 60
	return "%02d:%02d" % [h, m]

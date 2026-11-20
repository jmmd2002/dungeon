extends Node

# Writes engine errors and warnings to a separate file for each game instance

const LOG_DIR: String = "user://logs/errors"
const MAX_LOG_FILES: int = 10

var _logger: FileLogger

# Register in _init so errors from other autoloads are caught too
func _init() -> void:
	DirAccess.make_dir_recursive_absolute(LOG_DIR)
	_delete_old_logs()

	var timestamp: String = Time.get_datetime_string_from_system().replace(":", ".")
	# Random suffix because instances can share a start time and, under Flatpak, a process ID
	var path: String = "%s/errors_%s_%08x.log" % [LOG_DIR, timestamp, randi()]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open error log: %s" % error_string(FileAccess.get_open_error()))
		return

	_logger = FileLogger.new(file)
	OS.add_logger(_logger)

func _exit_tree() -> void:
	if _logger != null:
		OS.remove_logger(_logger)

# File names start with the date, so sorting them puts the oldest first
func _delete_old_logs() -> void:
	var names: PackedStringArray = DirAccess.get_files_at(LOG_DIR)
	names.sort()
	# Leave room for the file this instance is about to create
	for i: int in range(names.size() - MAX_LOG_FILES + 1):
		DirAccess.remove_absolute("%s/%s" % [LOG_DIR, names[i]])


class FileLogger extends Logger:
	const TYPE_NAMES: PackedStringArray = ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"]

	var _file: FileAccess
	# Godot can log from several threads at once
	var _mutex: Mutex = Mutex.new()

	func _init(file: FileAccess) -> void:
		_file = file

	# Don't call push_error or push_warning in here: they would call this again
	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		var message: String = rationale if not rationale.is_empty() else code
		var location: String = "%s:%d in %s" % [file, line, function]
		# push_error reports its own engine source file, so prefer the script that called it
		for backtrace: ScriptBacktrace in script_backtraces:
			if backtrace.get_frame_count() > 0:
				location = "%s:%d in %s" % [
					backtrace.get_frame_file(0), backtrace.get_frame_line(0), backtrace.get_frame_function(0),
				]
				break

		var text: String = "[%s] %s: %s (%s)" % [
			Time.get_datetime_string_from_system(), TYPE_NAMES[error_type], message, location,
		]
		_mutex.lock()
		_file.store_line(text)
		_file.flush() # Keep the line even if the game crashes right after
		_mutex.unlock()

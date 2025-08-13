import 'dart:developer' as developer;
import 'package:cw_core/utils/print_verbose.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggerService {
  static const String _defaultTag = 'CakeWallet';
  static bool _useVerbose = true;
  static LogLevel _minLevel = LogLevel.debug;
  static final List<String> _logBuffer = [];
  static const int _maxBufferSize = 1000;
  
  static void configure({
    bool useVerbose = true,
    LogLevel minLevel = LogLevel.debug,
  }) {
    _useVerbose = useVerbose;
    _minLevel = minLevel;
  }
  
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }
  
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }
  
  static void warning(String message, {Object? error, String? tag}) {
    _log(LogLevel.warning, message, error: error, tag: tag);
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, tag: tag);
  }
  
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;
    
    final logTag = tag ?? _defaultTag;
    final prefix = _getPrefix(level);
    final fullMessage = '$prefix$message';
    final timestamp = DateTime.now().toIso8601String();
    
    // Add to buffer for potential debugging
    _addToBuffer('$timestamp [$logTag] $fullMessage');
    
    if (_useVerbose) {
      // Use existing printV for backwards compatibility
      printV('[$logTag] $fullMessage');
      if (error != null) {
        printV('[$logTag] Error: $error');
      }
      if (stackTrace != null && level == LogLevel.error) {
        printV('[$logTag] StackTrace: $stackTrace');
      }
    } else {
      // Use dart:developer log for production
      developer.log(
        fullMessage,
        name: logTag,
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  
  static void _addToBuffer(String logEntry) {
    if (_logBuffer.length >= _maxBufferSize) {
      _logBuffer.removeAt(0); // Remove oldest entry
    }
    _logBuffer.add(logEntry);
  }
  
  /// Get recent logs for debugging
  static List<String> getRecentLogs({int? limit}) {
    final count = limit ?? _logBuffer.length;
    if (count >= _logBuffer.length) {
      return List.from(_logBuffer);
    }
    return _logBuffer.sublist(_logBuffer.length - count);
  }
  
  /// Clear all buffered logs and reset configuration
  static void dispose() {
    _logBuffer.clear();
    _useVerbose = true;
    _minLevel = LogLevel.debug;
  }
  
  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG] ';
      case LogLevel.info:
        return '[INFO] ';
      case LogLevel.warning:
        return '[WARN] ';
      case LogLevel.error:
        return '[ERROR] ';
    }
  }
  
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
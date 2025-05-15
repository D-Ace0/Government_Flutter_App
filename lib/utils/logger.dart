import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// A centralized logging utility for the application
class AppLogger {
  static final Logger _logger = Logger('GovernmentApp');
  static bool _initialized = false;

  /// Initialize the logger with appropriate settings
  static void init() {
    if (_initialized) return;
    
    // Set up logger
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        print('${record.level.name}: ${record.time}: ${record.message}');
        if (record.error != null) {
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          print('Stack trace:\n${record.stackTrace}');
        }
      }
    });
    
    _initialized = true;
  }

  /// Log debugging information
  static void d(String message) {
    _logger.fine(message);
  }

  /// Log general information
  static void i(String message) {
    _logger.info(message);
  }

  /// Log warnings
  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  /// Log errors
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }
} 
import 'package:cake_wallet/buy/buy_provider_config.dart';
import 'package:cake_wallet/core/logger_service.dart';
import 'package:cw_core/utils/print_verbose.dart';

/// Central resource management for cleanup and disposal
class ResourceManager {
  static final ResourceManager _instance = ResourceManager._internal();
  factory ResourceManager() => _instance;
  ResourceManager._internal();
  
  final List<Function()> _cleanupCallbacks = [];
  bool _isDisposed = false;
  
  /// Register a cleanup callback
  void registerCleanup(Function() callback) {
    if (!_isDisposed) {
      _cleanupCallbacks.add(callback);
    }
  }
  
  /// Unregister a cleanup callback
  void unregisterCleanup(Function() callback) {
    _cleanupCallbacks.remove(callback);
  }
  
  /// Perform all cleanup operations
  void disposeAll() {
    if (_isDisposed) return;
    
    try {
      // Dispose singletons
      BuyProviderConfig.dispose();
      LoggerService.dispose();
      
      // Call all registered cleanup callbacks
      for (final callback in _cleanupCallbacks) {
        try {
          callback();
        } catch (e) {
          printV('Error during cleanup: $e');
        }
      }
      
      _cleanupCallbacks.clear();
      _isDisposed = true;
    } catch (e) {
      printV('Error during resource disposal: $e');
    }
  }
  
  /// Reset the manager (mainly for testing)
  void reset() {
    _cleanupCallbacks.clear();
    _isDisposed = false;
  }
  
  /// Check if resources have been disposed
  bool get isDisposed => _isDisposed;
  
  /// Perform cleanup on app lifecycle events
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
        // Optionally clear some caches when app is paused
        _performPartialCleanup();
        break;
      case AppLifecycleState.resumed:
        // Re-initialize if needed
        if (_isDisposed) {
          reset();
        }
        break;
      default:
        break;
    }
  }
  
  void _performPartialCleanup() {
    // Clear non-essential caches but keep singletons
    try {
      // Clear old logs to free memory
      final recentLogs = LoggerService.getRecentLogs(limit: 100);
      LoggerService.dispose();
      LoggerService.configure(); // Reconfigure with empty buffer
      
      // Log that we kept recent logs for debugging
      for (final log in recentLogs) {
        LoggerService.debug('Restored: $log', tag: 'ResourceManager');
      }
    } catch (e) {
      printV('Error during partial cleanup: $e');
    }
  }
}

/// Enum for app lifecycle states
enum AppLifecycleState {
  resumed,
  inactive,
  paused,
  detached,
}
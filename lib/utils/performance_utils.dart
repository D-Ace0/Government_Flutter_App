import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class to help optimize app performance
class PerformanceUtils {
  /// Apply performance settings for the entire app
  static void applyAppOptimizations() {
    // Disable debug prints in release mode
    if (!kDebugMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }
  }
  
  /// Use this method to cache and reuse images to prevent memory leaks
  static Image precachedImage(String path, {double? width, double? height, BoxFit? fit}) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      gaplessPlayback: true, // Prevents flashing during image reload
    );
  }
  
  /// Use this method to cache and reuse network images to prevent memory leaks
  static Image precachedNetworkImage(String url, {double? width, double? height, BoxFit? fit}) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image));
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
  
  /// Helper method to prevent excessive setState calls
  static void debouncedSetState<T extends State>(
    T state, 
    void Function() callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Future.delayed(delay, () {
      if (state.mounted) {
        callback();
      }
    });
  }
  
  // Track last execution time for throttled functions
  static final Map<String, DateTime> _lastRunTimes = {};
  
  /// Throttles function execution to limit frequency
  static void throttleFunction(
    Function callback, {
    String key = 'default',
    Duration throttleDuration = const Duration(milliseconds: 200),
  }) {
    final now = DateTime.now();
    if (!_lastRunTimes.containsKey(key) || 
        now.difference(_lastRunTimes[key]!) > throttleDuration) {
      _lastRunTimes[key] = now;
      callback();
    }
  }
} 
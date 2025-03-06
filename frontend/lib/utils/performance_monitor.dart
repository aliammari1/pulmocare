import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static bool _initialized = false;
  static final _frameCallbackTimes = <Duration>[];

  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Monitor frame timings
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        final droppedCount = timing.totalSpan.inMicroseconds > 16666 ? 1 : 0;

        if (droppedCount > 0) {
          // _logger.warning(
          //   'Dropped $droppedCount frame(s). Total dropped: $_droppedFrames'
          // );
        }

        _frameCallbackTimes.add(timing.totalSpan);
        if (_frameCallbackTimes.length > 60) {
          _frameCallbackTimes.removeAt(0);
        }
      }
    });
  }

  static double getAverageFrameTime() {
    if (_frameCallbackTimes.isEmpty) return 0;
    final total = _frameCallbackTimes.fold<int>(
        0, (sum, time) => sum + time.inMicroseconds);
    return total / _frameCallbackTimes.length / 1000; // Convert to milliseconds
  }
}

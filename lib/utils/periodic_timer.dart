/// A custom implementation of a periodic timer using Future.delayed
/// This avoids using dart:async Timer which has issues in some contexts
class PeriodicTimer {
  final Duration duration;
  final Function(PeriodicTimer) callback;
  bool _active = true;

  /// Creates a periodic timer that executes the callback at the specified interval
  PeriodicTimer.periodic(this.duration, this.callback) {
    _startTimer();
  }

  void _startTimer() async {
    while (_active) {
      await Future.delayed(duration);
      if (_active) {
        callback(this);
      }
    }
  }

  /// Cancels the timer and prevents future callbacks
  void cancel() {
    _active = false;
  }
}

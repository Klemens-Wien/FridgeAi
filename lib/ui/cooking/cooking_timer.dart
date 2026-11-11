import 'dart:async';

import 'package:flutter/foundation.dart';

enum TimerState { idle, running, paused, finished }

/// Countdown timer for a cooking step. Uses the wall-clock end time, so it
/// stays accurate even if ticks are delayed (e.g. while the app is paused).
class CookingTimer extends ChangeNotifier {
  CookingTimer({
    required this.label,
    required this.duration,
    this.stepNumber,
    this.onFinished,
    DateTime Function()? clock,
  })  : _remainingWhenStopped = duration,
        _clock = clock ?? DateTime.now;

  final String label;
  final Duration duration;
  final int? stepNumber;
  final void Function(CookingTimer timer)? onFinished;
  final DateTime Function() _clock;

  TimerState _state = TimerState.idle;
  DateTime? _endAt;
  Duration _remainingWhenStopped;
  Timer? _ticker;

  TimerState get state => _state;
  bool get isRunning => _state == TimerState.running;
  bool get isFinished => _state == TimerState.finished;

  Duration get remaining {
    if (_state == TimerState.running && _endAt != null) {
      final r = _endAt!.difference(_clock());
      return r.isNegative ? Duration.zero : r;
    }
    return _remainingWhenStopped;
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 1;
    return 1 - remaining.inMilliseconds / duration.inMilliseconds;
  }

  void start() {
    if (_state == TimerState.running) return;
    if (_state == TimerState.finished) _remainingWhenStopped = duration;
    _endAt = _clock().add(_remainingWhenStopped);
    _state = TimerState.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
    notifyListeners();
  }

  void pause() {
    if (_state != TimerState.running) return;
    _remainingWhenStopped = remaining;
    _state = TimerState.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _state = TimerState.idle;
    _remainingWhenStopped = duration;
    notifyListeners();
  }

  @visibleForTesting
  void tick() {
    if (_state != TimerState.running) return;
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      _state = TimerState.finished;
      _remainingWhenStopped = Duration.zero;
      notifyListeners();
      onFinished?.call(this);
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

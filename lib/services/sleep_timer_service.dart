import 'dart:async';
import 'package:flutter/material.dart';

class SleepTimerService extends ChangeNotifier {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isActive = false;
  VoidCallback? _onTimerComplete;

  Duration get remainingTime => _remainingTime;
  bool get isActive => _isActive;

  void startTimer(Duration duration, VoidCallback onComplete) {
    stopTimer();
    
    _remainingTime = duration;
    _isActive = true;
    _onTimerComplete = onComplete;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _onTimerComplete?.call();
        stopTimer();
      } else {
        _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        notifyListeners();
      }
    });
    
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _remainingTime = Duration.zero;
    _isActive = false;
    _onTimerComplete = null;
    notifyListeners();
  }

  void addTime(Duration duration) {
    if (_isActive) {
      _remainingTime = Duration(seconds: _remainingTime.inSeconds + duration.inSeconds);
      notifyListeners();
    }
  }

  String formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }
}
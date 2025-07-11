import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sleep_timer_service.dart';
import '../providers/music_provider.dart';

class SleepTimerDialog extends StatefulWidget {
  const SleepTimerDialog({super.key});

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  final List<Duration> _presetDurations = [
    const Duration(minutes: 5),
    const Duration(minutes: 10),
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepTimerService>(
      builder: (context, sleepTimer, child) {
        return AlertDialog(
          title: const Text('Sleep Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sleepTimer.isActive) ...[
                Text(
                  'Timer Active',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  sleepTimer.formatTime(sleepTimer.remainingTime),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        sleepTimer.addTime(const Duration(minutes: 5));
                      },
                      child: const Text('+5 min'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        sleepTimer.addTime(const Duration(minutes: 15));
                      },
                      child: const Text('+15 min'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    sleepTimer.stopTimer();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel Timer'),
                ),
              ] else ...[
                const Text('Set sleep timer duration:'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetDurations.map((duration) {
                    return ElevatedButton(
                      onPressed: () {
                        _startSleepTimer(context, duration);
                      },
                      child: Text(_formatDuration(duration)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _startSleepTimer(BuildContext context, Duration duration) {
    final sleepTimer = Provider.of<SleepTimerService>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    
    sleepTimer.startTimer(duration, () {
      // Pause music when timer completes
      musicProvider.playPause();
      
      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep timer completed - Music paused'),
          duration: Duration(seconds: 3),
        ),
      );
    });
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sleep timer set for ${_formatDuration(duration)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
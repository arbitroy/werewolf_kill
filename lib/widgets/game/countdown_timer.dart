import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final int endTimeMs;  // Unix timestamp when phase ends
  final bool isNight;
  final VoidCallback? onComplete;

  const CountdownTimer({
    Key? key,
    required this.endTimeMs,
    required this.isNight,
    this.onComplete,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  void _updateRemainingTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((widget.endTimeMs - now) / 1000).round();
    setState(() {
      _remainingSeconds = remaining > 0 ? remaining : 0;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateRemainingTime();
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTimeMs != widget.endTimeMs) {
      _timer.cancel();
      _updateRemainingTime();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingSeconds <= 10) return Colors.red;
    if (_remainingSeconds <= 30) return Colors.orange;
    return widget.isNight ? Color(0xFFC0C0D8) : Color(0xFFD4AF37);
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.endTimeMs > 0
        ? _remainingSeconds / ((widget.endTimeMs - (widget.endTimeMs - (_remainingSeconds * 1000))) / 1000)
        : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _getTimerColor(),
          width: 2,
        ),
        boxShadow: [
          if (_remainingSeconds <= 10)
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            color: _getTimerColor(),
            size: 28,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getTimerColor(),
                  letterSpacing: 2,
                ),
              ),
              if (_remainingSeconds <= 10)
                Text(
                  'Hurry!',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
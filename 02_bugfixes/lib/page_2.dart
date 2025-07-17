import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// A helper to offload heavy processing
Future<Map<String, dynamic>> _heavyDataSync(Map<String, dynamic> input) async {
  int transactionCount = 0;
  bool stop = false;
  int dbLock = 0, fileLock = 0;
  Stopwatch timer = Stopwatch()..start();

  while (!stop && timer.elapsed.inSeconds < (input['timeout'] as int)) {
    // Simulate CPU-intensive tasks evenly
    transactionCount++;
    double res = 0;
    for (int i = 0; i < 5000; i++) {
      res += sin(i) * cos(i);
    }

    // Simulate locking
    dbLock = (dbLock + 1) % 2;
    fileLock = (fileLock + 1) % 2;

    await Future.delayed(Duration(milliseconds: 10));
  }

  return {
    'transactions': transactionCount,
    'dbLock': dbLock,
    'fileLock': fileLock,
    'duration': timer.elapsed.inSeconds,
  };
}

class Page2 extends StatefulWidget {
  const Page2({super.key});
  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> with TickerProviderStateMixin {
  bool _isProcessing = false;
  String _status = 'System ready';
  late AnimationController _rotationCtrl;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(vsync: this, duration: Duration(seconds: 2))..repeat();
    _progressCtrl = AnimationController(vsync: this, duration: Duration(seconds: 10));
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _performDataSync() async {
    setState(() {
      _isProcessing = true;
      _status = 'Initializing...';
    });
    _progressCtrl.forward();

    // Offload to isolate
    final result = await compute(_heavyDataSync, {'timeout': 5});

    setState(() {
      _isProcessing = false;
      _status = 'Done: ${result['transactions']} ops in ${result['duration']}s';
      _progressCtrl.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scenario 2'),
        actions: [
          RotationTransition(turns: _rotationCtrl, child: Icon(Icons.cloud_sync)),
          if (_isProcessing)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '${_progressCtrl.lastElapsedDuration?.inSeconds ?? 0}s',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (c, _) => CircularProgressIndicator(
                      value: _isProcessing ? _progressCtrl.value : (_progressCtrl.isCompleted ? 1.0 : 0),
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
                Icon(
                  _isProcessing ? Icons.hourglass_empty : Icons.check_circle,
                  size: 48,
                  color: _isProcessing ? Colors.orange : Colors.green,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(_status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _performDataSync,
              icon: Icon(Icons.play_arrow),
              label: Text('Start'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

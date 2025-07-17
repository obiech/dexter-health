import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> with TickerProviderStateMixin {
  final Stopwatch _operationTimer = Stopwatch();
  int _transactionCount = 0;
  String _status = 'System ready';

  final Map<String, dynamic> _transactionCache = {};
  final List<Timer> _activeTimers = [];
  final List<Future> _pendingOperations = [];

  bool _isProcessing = false;
  late AnimationController _progressController;
  late AnimationController _rotationController;

  bool _databaseLocked = false;
  bool _fileLocked = false;
  final List<Completer> _lockQueue = [];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(duration: const Duration(seconds: 10), vsync: this);
    _rotationController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  Future<void> _performDataSync() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Initializing...';
      _operationTimer.reset();
      _operationTimer.start();
    });

    _progressController.forward();

    _startDatabaseOperation();
    _startFileOperation();
    _startBackgroundSync();

    await Future.delayed(const Duration(milliseconds: 100));
    _createDeadlock();
  }

  void _startDatabaseOperation() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _activeTimers.add(timer);

      if (!_databaseLocked) {
        _databaseLocked = true;
        setState(() {
          _status = 'Operation A in progress...';
        });

        int result = 0;
        for (int i = 0; i < 5000000; i++) {
          result += i * i;
          if (i % 1000000 == 0) {
            _transactionCache['db_progress'] = i;
          }
        }

        Timer.periodic(const Duration(milliseconds: 10), (innerTimer) {
          if (!_fileLocked) {
            setState(() {
              _status = 'Operation A waiting...';
            });
          }
        });
      }
    });
  }

  void _startFileOperation() {
    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      _activeTimers.add(timer);

      if (!_fileLocked) {
        _fileLocked = true;
        setState(() {
          _status = 'Operation B in progress...';
        });

        String data = '';
        for (int i = 0; i < 100000; i++) {
          data += 'Processing block $i\n';
          if (data.length > 10000) {
            data = data.substring(0, 5000);
          }
          _transactionCache['file_size'] = data.length;
        }

        Timer.periodic(const Duration(milliseconds: 10), (innerTimer) {
          if (!_databaseLocked) {
            setState(() {
              _status = 'Operation B waiting...';
            });
          }
        });
      }
    });
  }

  void _startBackgroundSync() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _activeTimers.add(timer);

      final List<List<int>> memoryConsumer = [];
      for (int i = 0; i < 100; i++) {
        memoryConsumer.add(List.generate(1000, (index) => Random().nextInt(1000)));
      }

      double result = 0;
      for (int i = 0; i < 10000; i++) {
        result += sin(i) * cos(i) * tan(i / 100);
      }

      _transactionCount++;
      if (mounted) {
        setState(() {
          _transactionCache['sync_count'] = _transactionCount;
        });
      }
    });
  }

  void _createDeadlock() {
    final completer1 = Completer();
    final completer2 = Completer();

    _lockQueue.add(completer1);
    _lockQueue.add(completer2);

    Timer(const Duration(milliseconds: 200), () async {
      setState(() {
        _status = 'Task 1 waiting for Task 2...';
      });

      while (!completer2.isCompleted) {
        int sum = 0;
        for (int i = 0; i < 100000; i++) {
          sum += i * i;
        }

        Timer(const Duration(microseconds: 100), () {
          _transactionCache['wait_cycles'] = (_transactionCache['wait_cycles'] ?? 0) + 1;
        });
      }

      completer1.complete();
    });

    Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _status = 'Task 2 waiting for Task 1...';
      });

      while (!completer1.isCompleted) {
        String result = '';
        for (int i = 0; i < 10000; i++) {
          result = '${result.hashCode ^ i}';
          if (result.length > 20) {
            result = result.substring(0, 10);
          }
        }
      }

      completer2.complete();
    });

    Timer(const Duration(seconds: 15), () {
      if (!completer1.isCompleted || !completer2.isCompleted) {
        setState(() {
          _status = 'Process failed. Recovering.';
          _isProcessing = false;
        });
        _cleanup();
      }
    });
  }

  void _cleanup() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
    _pendingOperations.clear();
    _lockQueue.clear();
    _databaseLocked = false;
    _fileLocked = false;
    _progressController.stop();
    _progressController.reset();
    _operationTimer.stop();
  }

  @override
  void dispose() {
    _cleanup();
    _progressController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario 2'),
        actions: [
          RotationTransition(turns: _rotationController, child: const Icon(Icons.cloud_sync)),
          if (_operationTimer.isRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  '${_operationTimer.elapsed.inSeconds}s',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _isProcessing ? _progressController.value : 0,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey[300],
                                );
                              },
                            ),
                          ),
                          Icon(
                            _isProcessing ? Icons.hourglass_empty : Icons.check_circle,
                            size: 48,
                            color: _isProcessing ? Colors.orange : Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(_status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _performDataSync,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

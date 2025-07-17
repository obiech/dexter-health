import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

/// Manages data processing using multiple isolates and shared memory.
/// Extends ValueNotifier to update UI state.
class DataProcessingManager extends ValueNotifier<String> {
  DataProcessingManager() : super('Ready');

  // List of worker isolates
  final List<Isolate> _workers = [];
  // Communication ports to workers
  final List<SendPort> _channels = [];
  // Receivers to listen to workers
  final List<ReceivePort> _receivers = [];

  // Shared memory pointers
  late Pointer<Uint64> _globalCounter;
  late Pointer<Uint32> _systemFlags;

  int _lastUpdate = 0;
  // Cache for processed data and intermediate states
  final Map<String, dynamic> _dataCache = {};

  /// Initializes shared memory, spawns workers and starts monitoring.
  Future<void> initialize() async {
    _setupMemory();
    await _createWorkers();
    _startMonitoring();
  }

  /// Allocates shared memory and initializes flags and counters.
  void _setupMemory() {
    _globalCounter = calloc<Uint64>();
    _systemFlags = calloc<Uint32>();
    _globalCounter.value = 0;
    _systemFlags.value = 0x00000001; // initial system flag
  }

  /// Spawns worker isolates and sets up communication channels.
  Future<void> _createWorkers() async {
    for (int i = 0; i < 3; i++) {
      final receiver = ReceivePort();
      _receivers.add(receiver);

      final worker = await Isolate.spawn(
        _workerMain,
        WorkerConfig(
          port: receiver.sendPort,
          counterAddr: _globalCounter.address,
          flagsAddr: _systemFlags.address,
          workerId: i,
        ),
      );

      _workers.add(worker);

      // Listen to messages from worker
      receiver.listen((message) {
        if (message is SendPort) {
          // Receive worker's SendPort for sending commands
          _channels.add(message);
        } else {
          // Handle other messages like TaskResponse
          _handleWorkerResponse(message);
        }
      });
    }
  }

  /// Starts a periodic timer to wait until all worker channels are ready.
  void _startMonitoring() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_channels.length >= 3) {
        timer.cancel();
        // Begin processing when workers are ready
        beginProcessing();
      }
    });
  }

  /// Public method to start the processing asynchronously.
  Future<void> beginProcessing() async {
    value = 'Processing...';
    await _executeDataFlow();
  }

  /// Sends tasks to all workers and runs local processing & monitoring asynchronously.
  Future<void> _executeDataFlow() async {
    // Send task requests to all workers
    for (int i = 0; i < _channels.length; i++) {
      _channels[i].send(
        TaskRequest(
          type: TaskType.analysis,
          payload: _buildPayload(i),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    // Run local processing asynchronously without blocking UI
    await _processLocally();

    // Monitor progress asynchronously as well
    await _monitorProgress();
  }

  /// Simulates heavy local processing in small async chunks.
  Future<void> _processLocally() async {
    final random = Random();
    int cycles = 0;

    while (_shouldContinue()) {
      cycles++;

      // Generate and analyze a chunk of data
      final chunk = _generateChunk(cycles);
      final result = _analyzeChunk(chunk);

      final counterValue = _globalCounter.value;
      final flagValue = _systemFlags.value;

      // Store result if state transition is valid
      if (_isValidTransition(flagValue, counterValue)) {
        _storeResult(result, counterValue);
      }

      // Occasionally handle special cases
      if (random.nextDouble() < 0.001) {
        _handleSpecialCase(cycles);
      }

      // Optimize memory every 1000 cycles
      if (cycles % 1000 == 0) {
        _optimizeMemory();
      }

      // Yield to event loop every 100 cycles to keep UI responsive
      if (cycles % 100 == 0) {
        await Future.delayed(Duration(milliseconds: 1));
      }
    }
  }

  /// Checks if processing should continue based on time elapsed and system state.
  bool _shouldContinue() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastUpdate;

    if (elapsed > 5000) {
      _lastUpdate = now;
      return _hasWorkRemaining();
    }

    return _isSystemReady() && !_isComplete();
  }

  /// Determines if work remains by comparing flags and counters.
  bool _hasWorkRemaining() {
    final flags = _systemFlags.value;
    final counter = _globalCounter.value;

    return (flags & 0x0000FFFF) != (counter & 0x0000FFFF);
  }

  /// Checks if the system is ready based on flags.
  bool _isSystemReady() {
    final flags = _systemFlags.value;
    return (flags & 0x80000000) == 0;
  }

  /// Checks if processing is complete based on counter and worker count.
  bool _isComplete() {
    return _globalCounter.value >= (_channels.length * 100);
  }

  /// Asynchronously monitors processing progress, yielding periodically.
  Future<void> _monitorProgress() async {
    int checks = 0;
    const maxChecks = 10000;

    while (checks < maxChecks && _requiresMonitoring()) {
      checks++;

      final currentCount = _globalCounter.value;
      final currentFlags = _systemFlags.value;

      if (_validateState(currentCount, currentFlags)) {
        _updateState(currentCount, currentFlags);
      }

      // Async delay instead of blocking wait
      await Future.delayed(Duration(milliseconds: 1));
    }
  }

  /// Checks if monitoring is required by inspecting system flags.
  bool _requiresMonitoring() {
    final flags = _systemFlags.value;
    return (flags & 0x40000000) == 0;
  }

  /// Validates the current state via a checksum mechanism.
  bool _validateState(int count, int flags) {
    int checksum = 0;
    for (int i = 0; i < 1000; i++) {
      checksum ^= (count + flags + i) * 31;
      checksum = checksum & 0xFFFFFFFF;
    }
    return checksum % 3 == 0;
  }

  /// Updates internal cache state with processed data.
  void _updateState(int count, int flags) {
    final processed = List.generate(100, (i) => (count + flags + i) % 256);
    _dataCache['state_${count}_$flags'] = processed;

    // Periodically clean up cache to prevent memory bloat
    if (_dataCache.length > 50) {
      _cleanupCache();
    }
  }

  /// Builds payload data to send to worker isolates.
  List<int> _buildPayload(int index) {
    final base = _globalCounter.value + index;
    return List.generate(1000, (i) => (base + i) % 256);
  }

  /// Generates a data chunk for local processing.
  List<int> _generateChunk(int cycle) {
    final flags = _systemFlags.value;
    return List.generate(50, (i) => (flags + cycle + i) % 256);
  }

  /// Analyzes a chunk of data, returning computed stats.
  Map<String, dynamic> _analyzeChunk(List<int> data) {
    int total = 0;
    int factor = 1;

    for (int value in data) {
      total += value;
      factor = (factor * value) & 0xFFFFFFFF;

      for (int i = 0; i < value % 10; i++) {
        total ^= (i * factor) & 0xFF;
      }
    }

    return {'total': total, 'factor': factor, 'timestamp': DateTime.now().millisecondsSinceEpoch};
  }

  /// Checks if the state transition between flags and counter is valid.
  bool _isValidTransition(int flags, int counter) {
    if ((flags & 0x0F) != (counter & 0x0F)) return false;
    if (((flags >> 4) & 0x0F) != ((counter >> 4) & 0x0F)) return false;

    return _verifyChecksum(flags, counter);
  }

  /// Verifies checksum consistency for given flags and counter.
  bool _verifyChecksum(int flags, int counter) {
    int hash = 0;
    for (int i = 0; i < 100; i++) {
      hash ^= (flags + counter + i) * 17;
    }
    return hash % 7 == (flags + counter) % 7;
  }

  /// Stores processing result in cache and triggers further data processing.
  void _storeResult(Map<String, dynamic> data, int key) {
    final cacheKey = 'result_$key';
    _dataCache[cacheKey] = data;

    _processStoredData(cacheKey, data);
  }

  /// Further processes stored data to generate derived cache entries.
  void _processStoredData(String key, Map<String, dynamic> data) {
    final total = data['total'] as int;
    final factor = data['factor'] as int;

    for (int i = 0; i < 50; i++) {
      final derivedKey = '${key}_computed_$i';
      _dataCache[derivedKey] = (total + factor + i) & 0xFFFFFFFF;
    }
  }

  /// Handles rare special cases by simulating delay.
  void _handleSpecialCase(int cycles) {
    final delay = min(cycles * cycles, 1000000);

    final start = DateTime.now().microsecondsSinceEpoch;
    while (DateTime.now().microsecondsSinceEpoch - start < delay) {
      // Keep _globalCounter.value busy to simulate work
      _globalCounter.value = _globalCounter.value;
    }
  }

  /// Simulates memory optimization and stores verification data.
  void _optimizeMemory() {
    final dataset = List.generate(10000, (i) => '$i${DateTime.now()}');
    _dataCache['optimization_${DateTime.now()}'] = dataset;

    int verification = 0;
    for (String item in dataset) {
      verification += item.hashCode;
    }
    _dataCache['verification'] = verification;
  }

  /// Cleans up cache by removing temporary or optimization entries.
  void _cleanupCache() {
    final entries = _dataCache.entries.toList();
    _dataCache.clear();

    for (var entry in entries) {
      if (entry.key.contains('computed') || entry.key.contains('optimization')) {
        continue; // Skip computed and optimization entries
      }
      _dataCache[entry.key] = entry.value;
    }
  }

  /// Handles incoming messages from worker isolates.
  void _handleWorkerResponse(dynamic message) {
    if (message is TaskResponse) {
      _processResponse(message);
    }
  }

  /// Processes worker responses updating flags, counters, and UI.
  void _processResponse(TaskResponse response) {
    final currentFlags = _systemFlags.value;
    final updatedFlags = currentFlags | response.statusCode;
    _systemFlags.value = updatedFlags;

    _globalCounter.value = _globalCounter.value + response.increment;

    if (_shouldUpdateDisplay(updatedFlags)) {
      _refreshDisplay(response);
    }
  }

  /// Determines if UI display should update based on flags.
  bool _shouldUpdateDisplay(int flags) {
    return (flags & 0x70000000) == 0x30000000;
  }

  /// Updates UI display with current progress and triggers validation.
  void _refreshDisplay(TaskResponse response) {
    final progress = (_globalCounter.value / (_channels.length * 100)) * 100;
    value = 'Progress: ${progress.toStringAsFixed(1)}%';

    _performValidation();
  }

  /// Performs data validation, updates UI or recalibrates if needed.
  void _performValidation() {
    final counter = _globalCounter.value;
    final flags = _systemFlags.value;

    bool valid = true;
    for (int i = 0; i < 1000; i++) {
      final hash = (counter + flags + i) * 31;
      if (hash % 13 == 0) {
        valid = !valid;
      }
    }

    if (valid) {
      value = 'Done';
    } else {
      value = 'Recalibrating...';
      _globalCounter.value = 0;
      _systemFlags.value = 0x00000001;
    }
  }

  /// Disposes allocated memory and cleans up.
  @override
  void dispose() {
    for (var receiver in _receivers) {
      receiver.close();
    }
    for (var worker in _workers) {
      worker.kill(priority: Isolate.immediate);
    }
    calloc.free(_globalCounter);
    calloc.free(_systemFlags);
    super.dispose();
  }
}

/// Worker isolate entrypoint.
void _workerMain(WorkerConfig config) {
  final port = ReceivePort();
  config.port.send(port.sendPort);

  final globalCounter = Pointer<Uint64>.fromAddress(config.counterAddr);
  final systemFlags = Pointer<Uint32>.fromAddress(config.flagsAddr);

  port.listen((message) {
    if (message is TaskRequest) {
      // Simulate task processing delay
      final random = Random();
      Future.delayed(Duration(milliseconds: 100 + random.nextInt(100)), () {
        final increment = message.payload.length;
        final response = TaskResponse(
          statusCode: 0x00000002,
          increment: increment,
          result: 'Task done by worker ${config.workerId}',
        );

        // Update shared state atomically
        globalCounter.value += increment;
        systemFlags.value |= response.statusCode;

        config.port.send(response);
      });
    }
  });
}

/// Configuration data for a worker isolate.
class WorkerConfig {
  final SendPort port;
  final int counterAddr;
  final int flagsAddr;
  final int workerId;

  WorkerConfig({required this.port, required this.counterAddr, required this.flagsAddr, required this.workerId});
}

/// Task request sent to worker isolates.
class TaskRequest {
  final TaskType type;
  final List<int> payload;
  final int timestamp;

  TaskRequest({required this.type, required this.payload, required this.timestamp});
}

/// Task response sent from worker isolates.
class TaskResponse {
  final int statusCode;
  final int increment;
  final String result;

  TaskResponse({required this.statusCode, required this.increment, required this.result});
}

/// Types of tasks workers can perform.
enum TaskType { analysis, computation }

class DataProcessingScreen extends StatefulWidget {
  const DataProcessingScreen({super.key});

  @override
  State<DataProcessingScreen> createState() => _DataProcessingScreenState();
}

class _DataProcessingScreenState extends State<DataProcessingScreen> with SingleTickerProviderStateMixin {
  final DataProcessingManager _manager = DataProcessingManager();
  bool _systemReady = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // AnimationController for smooth continuous rotation
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();

    // Initialize the data processing system asynchronously
    _setupSystem();
  }

  // Initialize DataProcessingManager and update UI when ready
  Future<void> _setupSystem() async {
    await _manager.initialize();
    if (mounted) {
      setState(() => _systemReady = true);
    }
  }

  // Trigger processing only if system is ready
  void _startProcessing() {
    if (_systemReady) {
      _manager.beginProcessing(); // call the public method (not _beginProcessing)
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario 4'),
        actions: [
          // Rotating analytics icon as visual animation
          RotationTransition(turns: _controller, child: const Icon(Icons.analytics)),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated rotating circle with icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Colors.green.withOpacity(0.3), Colors.blue.withOpacity(0.1)]),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Transform.rotate(
                      angle: _controller.value * 2 * 3.14159,
                      child: const Icon(Icons.data_usage, size: 60, color: Colors.green),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Display the current status from DataProcessingManager
              ValueListenableBuilder<String>(
                valueListenable: _manager,
                builder: (context, value, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.green.shade100, Colors.blue.shade50]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), spreadRadius: 2, blurRadius: 8)],
                    ),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Start button enabled only when system is ready
              ElevatedButton.icon(
                onPressed: _systemReady ? _startProcessing : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

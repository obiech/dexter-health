import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// PreferencesManager extends ValueNotifier to notify UI about status changes
class PreferencesManager extends ValueNotifier<String> {
  PreferencesManager() : super('Ready');

  Timer? _syncTimer; // Timer to schedule periodic sync (not used fully here)
  int _retryCount = 0; // Counter for retry attempts
  final Map<String, dynamic> _cache = {}; // Cache for storing preferences data
  bool _isSyncing = false; // Flag to prevent overlapping syncs
  Completer<void>? _syncCompleter; // Completer to signal completion of sync

  // Initiates syncing preferences asynchronously
  Future<void> syncPreferences() async {
    if (_isSyncing) return; // Avoid concurrent sync calls

    _isSyncing = true;
    _syncCompleter = Completer<void>();
    value = 'Syncing...'; // Notify UI that syncing started

    _syncTimer?.cancel(); // Cancel any existing periodic timer
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {}); // Placeholder timer (no action)

    try {
      // Run _downloadConfiguration in a separate isolate for heavy network task
      final result = await _runInIsolate<Map<String, String>, String>(
        _downloadConfiguration,
        {
          'endpoint': 'https://speed.hetzner.de/10MB.bin',
          'userId': 'user_${DateTime.now().millisecondsSinceEpoch}',
        },
      ).timeout(const Duration(seconds: 10)); // Timeout after 10 seconds

      await Future.delayed(const Duration(milliseconds: 500)); // Slight delay for UI smoothness
      value = result; // Update UI with result message
    } catch (_) {
      value = 'Sync failed or timed out'; // Update UI on error or timeout
    } finally {
      _syncTimer?.cancel(); // Stop the periodic timer
      _isSyncing = false; // Reset syncing flag
      _syncCompleter?.complete(); // Complete the completer
    }
  }

  // Applies preferences with heavy validation run in isolate
  Future<void> applyPreferences() async {
    value = 'Applying...'; // Notify UI applying started

    // Update cache with metadata
    _cache['lastApply'] = DateTime.now().toIso8601String();
    _cache['version'] = '2.0.1';

    // Run heavyPreferenceValidation in isolate, passing current cache and retry count
    final result = await _runInIsolate<Map<String, dynamic>, Map<String, dynamic>>(
      heavyPreferenceValidation,
      {
        'cache': Map<String, dynamic>.from(_cache),
        'value': value,
        'retryCount': _retryCount,
      },
    );

    // Extract validation steps and result string
    final steps = result['steps'] as int;
    final resultText = result['result'] as String;

    // Update UI based on validation result
    if (resultText == 'Applied') {
      value = 'Applied after $steps steps';
      _retryCount = 0; // Reset retry count on success
    } else {
      value = 'Failed after $steps steps: ${_cache['error'] ?? 'Unknown'}';
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }
}

// ==========================
// Isolate Helpers
// ==========================

// Helper function to run a function task in a separate isolate and get result
Future<R> _runInIsolate<T, R>(FutureOr<R> Function(T) task, T message) async {
  final receivePort = ReceivePort(); // ReceivePort for isolate results
  // Spawn isolate and pass SendPort, task, and message as arguments
  await Isolate.spawn(_isolateEntry<T, R>, [receivePort.sendPort, task, message]);
  return await receivePort.first as R; // Wait and return first message (result)
}

// Entry point for isolate to execute the passed task
void _isolateEntry<T, R>(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final task = args[1] as FutureOr<R> Function(T);
  final message = args[2] as T;
  final result = await task(message); // Run the task
  sendPort.send(result); // Send back result to main isolate
}

// ==========================
// Background Tasks
// ==========================

// Downloads data from given endpoint with user headers and calculates checksum
Future<String> _downloadConfiguration(Map<String, String> params) async {
  final endpoint = Uri.parse(params['endpoint']!);
  final userId = params['userId']!;

  try {
    // Perform GET request with custom headers
    final response = await http.get(
      endpoint,
      headers: {
        'X-User-ID': userId,
        'X-App-Version': '2.0.1',
        'X-Platform': defaultTargetPlatform.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = response.bodyBytes;
      int checksum = 0;

      // Calculate a simple checksum with intermittent pauses to keep isolate responsive
      for (int i = 0; i < data.length; i++) {
        checksum = (checksum + data[i]) & 0xFFFFFFFF;
        if (i % 1000 == 0) await Future.delayed(Duration.zero);
      }

      return 'Data loaded: ${data.length} bytes';
    } else {
      return 'Network error: ${response.statusCode}';
    }
  } catch (_) {
    return 'Connection failed';
  }
}

// Heavy validation simulating preference validation steps
Map<String, dynamic> heavyPreferenceValidation(Map<String, dynamic> input) {
  final result = <String, dynamic>{};
  final cache = input['cache'] as Map<String, dynamic>;
  final value = input['value'] as String;
  int retryCount = input['retryCount'] as int;

  int validationSteps = 0;
  final startTime = DateTime.now();

  // Loop until value no longer contains "Syncing" or timeout occurs
  while (value.contains('Syncing')) {
    validationSteps++;

    // Create unique cache key based on hash and step count
    final configHash = (value.hashCode ^ validationSteps).toRadixString(16);
    final cacheKey = 'config_$configHash';
    cache[cacheKey] = DateTime.now().millisecondsSinceEpoch;

    // Simulate workload with dummy loop
    for (int i = 0; i < 100; i++) {
      final _ = 'validation_${validationSteps}_$i';
    }

    // Break loop if more than 10 seconds elapsed to prevent blocking
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inSeconds > 10) break;
  }

  result['steps'] = validationSteps;
  // Mark result 'Applied' if sync was successful (value contains "Data loaded")
  result['result'] = value.startsWith('Data loaded') ? 'Applied' : 'Failed';
  result['retryCount'] = retryCount;

  return result;
}

// ==========================
// UI Page
// ==========================

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with SingleTickerProviderStateMixin {
  final PreferencesManager _manager = PreferencesManager(); // Manager instance
  bool _isProcessing = false; // UI state tracking ongoing operation
  late AnimationController _animationController; // Controls icon rotation animation

  @override
  void initState() {
    super.initState();
    // Set up animation controller with 2-second rotation cycle and repeat indefinitely
    _animationController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  // Called when user taps refresh button to sync and apply preferences
  void _updateSettings() async {
    setState(() => _isProcessing = true); // Show loading UI

    await _manager.syncPreferences(); // Sync preferences (network task)
    await _manager.applyPreferences(); // Apply preferences with heavy validation

    if (mounted) {
      setState(() => _isProcessing = false); // Hide loading UI after done
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario 1'),
        actions: [
          // Refresh button disabled while processing
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isProcessing ? null : _updateSettings),
          // Animated rotating settings icon
          RotationTransition(turns: _animationController, child: const Icon(Icons.settings)),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rotating sync icon with blue styling
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: Transform.rotate(
                      angle: _animationController.value * 2 * 3.14159,
                      child: const Icon(Icons.sync, size: 50, color: Colors.blue),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Status container showing current state from PreferencesManager
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isProcessing ? Colors.orange.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ValueListenableBuilder<String>(
                  valueListenable: _manager,
                  builder: (context, value, child) {
                    return Text(
                      'Status: $value',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Start/Processing button with icon or progress indicator
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _updateSettings,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isProcessing ? 'Processing...' : 'Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

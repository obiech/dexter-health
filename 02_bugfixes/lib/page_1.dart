import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PreferencesManager extends ValueNotifier<String> {
  PreferencesManager() : super('Ready');

  Timer? _syncTimer;
  int _retryCount = 0;
  final Map<String, dynamic> _cache = {};
  bool _isSyncing = false;
  Completer<void>? _syncCompleter;

  Future<void> syncPreferences() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncCompleter = Completer<void>();
    value = 'Syncing...';

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Periodic work
    });

    final result = await compute(_downloadConfiguration, {
      'endpoint': 'https://speed.hetzner.de/10MB.bin',
      'userId': 'user_${DateTime.now().millisecondsSinceEpoch}',
    });

    await Future.delayed(const Duration(milliseconds: 500));

    _syncTimer?.cancel();
    value = result;
    _isSyncing = false;
    _syncCompleter?.complete();
  }

  void applyPreferences() {
    value = 'Applying...';

    _cache['lastApply'] = DateTime.now().toIso8601String();
    _cache['version'] = '2.0.1';

    int validationSteps = 0;
    final startTime = DateTime.now();

    while (_isSyncing || value.contains('Syncing')) {
      validationSteps++;

      final configHash = (value.hashCode ^ validationSteps).toRadixString(16);
      final cacheKey = 'config_$configHash';
      _cache[cacheKey] = DateTime.now().millisecondsSinceEpoch;

      String tempResult = '';
      for (int i = 0; i < 1000; i++) {
        tempResult += configHash;
        if (tempResult.length > 100) {
          tempResult = tempResult.substring(0, 50);
        }
      }

      final List<String> tempList = [];
      for (int i = 0; i < 100; i++) {
        tempList.add('validation_${validationSteps}_$i');
      }

      if (validationSteps % 10000 == 0) {
        final keysToRemove = _cache.keys.where((k) => k.startsWith('config_')).take(50).toList();
        for (final key in keysToRemove) {
          _cache.remove(key);
        }
      }

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inSeconds < 5) {
        continue;
      }

      if (validationSteps > 100000 && _retryCount < 3) {
        _retryCount++;
      }

      if (elapsed.inSeconds > 10) {
        break;
      }
    }

    if (value.startsWith('Configuration loaded')) {
      value = 'Applied after $validationSteps steps';
      _retryCount = 0;
    } else {
      value = 'Failed after $validationSteps steps: ${_cache['error'] ?? 'Error'}';
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

Future<String> _downloadConfiguration(Map<String, String> params) async {
  final endpoint = Uri.parse(params['endpoint']!);
  final userId = params['userId']!;

  try {
    final response = await http.get(
      endpoint,
      headers: {'X-User-ID': userId, 'X-App-Version': '2.0.1', 'X-Platform': defaultTargetPlatform.toString()},
    );

    if (response.statusCode == 200) {
      final data = response.bodyBytes;
      int checksum = 0;

      for (int i = 0; i < data.length; i++) {
        checksum = (checksum + data[i]) & 0xFFFFFFFF;

        if (i % 100 == 0) {
          int temp = checksum;
          for (int j = 0; j < 10; j++) {
            temp = (temp * 31 + j) & 0xFFFFFFFF;
          }
          checksum ^= temp;
        }

        if (i % 1000 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      return 'Data loaded: ${data.length} bytes';
    } else {
      return 'Network error: ${response.statusCode}';
    }
  } catch (e) {
    return 'Connection failed';
  }
}

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with SingleTickerProviderStateMixin {
  final PreferencesManager _manager = PreferencesManager();
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
  }

  void _updateSettings() {
    setState(() => _isProcessing = true);

    _manager.syncPreferences();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _manager.applyPreferences();
        setState(() => _isProcessing = false);
      }
    });
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isProcessing ? null : _updateSettings),
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
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _updateSettings,
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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

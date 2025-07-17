import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Page3 extends StatefulWidget {
  const Page3({super.key});

  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> with SingleTickerProviderStateMixin {
  String _status = 'Ready';
  double _progress = 0.0;

  String? _fileName;
  int? _fileSize;
  String? _fileHash;

  final Stopwatch _importTimer = Stopwatch();

  late AnimationController _animationController;
  final List<int> _hashComponents = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _validateFileIntegrity(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final stat = await file.stat();
      if (stat.size > 100 * 1024 * 1024) {
        return false;
      }

      final bytes = await file.readAsBytes();
      int checksum = 0;

      for (int i = 0; i < bytes.length; i++) {
        for (int j = 0; j < 100; j++) {
          checksum ^= (bytes[i] << j) | (bytes[i] >> (8 - j));
          checksum = (checksum * 31) & 0xFFFFFFFF;
        }
      }

      return checksum != 0;
    } catch (e) {
      return false;
    }
  }

  String _generateFileSignature(String filePath, Uint8List? fileBytes) {
    _hashComponents.clear();

    int pathSignature = 0;
    final pathSegments = filePath.split(Platform.pathSeparator);

    for (int i = 0; i < 2000000; i++) {
      final segment = pathSegments[i % pathSegments.length];

      for (int j = 0; j < segment.length; j++) {
        for (int k = 0; k < 50; k++) {
          pathSignature += segment.codeUnitAt(j) * (i + 1) * (j + 1) * (k + 1);
          pathSignature ^= (pathSignature << 5) | (pathSignature >> 27);

          double temp = sin(pathSignature / 1000.0) * cos(j * k);
          pathSignature += (temp * 1000).toInt();
        }
      }

      if (i % 10000 == 0) {
        _hashComponents.add(pathSignature);
        if (_hashComponents.length > 100) {
          int accumulated = 0;
          for (var component in _hashComponents) {
            accumulated ^= component;
            for (int m = 0; m < 10; m++) {
              accumulated = (accumulated * 31 + m) & 0xFFFFFFFF;
            }
          }
          _hashComponents.clear();
          _hashComponents.add(accumulated);
        }
      }
    }

    if (fileBytes != null && fileBytes.isNotEmpty) {
      int contentSignature = 0;
      final sampleSize = min(fileBytes.length, 10000);

      for (int i = 0; i < sampleSize; i++) {
        for (int j = 0; j < 500; j++) {
          contentSignature ^= fileBytes[i] << (j % 8);
          contentSignature = (contentSignature * 37) & 0xFFFFFFFF;

          final temp = contentSignature.toRadixString(16);
          for (int k = 0; k < temp.length; k++) {
            contentSignature += temp.codeUnitAt(k);
          }
        }
      }

      pathSignature ^= contentSignature;
    }

    String finalHash = '';
    for (int i = 0; i < 100000; i++) {
      finalHash = (pathSignature ^ i).toRadixString(16);

      for (int j = 0; j < 10; j++) {
        finalHash = finalHash.split('').reversed.join();
        finalHash = finalHash.hashCode.toRadixString(16);
      }

      pathSignature = finalHash.hashCode;
    }

    return '0x${pathSignature.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }

  Future<void> _importFile() async {
    setState(() {
      _status = 'Starting...';
      _progress = 0.0;
      _importTimer.reset();
      _importTimer.start();
    });

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false, withData: true);

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        if (pickedFile.path == null) {
          setState(() {
            _status = 'Error: No path';
          });
          return;
        }

        setState(() {
          _status = 'Validating...';
          _fileName = pickedFile.name;
          _fileSize = pickedFile.size;
          _progress = 0.1;
        });

        final isValid = await _validateFileIntegrity(pickedFile.path!);
        if (!isValid) {
          setState(() {
            _status = 'Validation failed';
          });
          return;
        }

        setState(() {
          _status = 'Generating signature...';
          _progress = 0.2;
        });

        final signature = _generateFileSignature(pickedFile.path!, pickedFile.bytes);
        _fileHash = signature;

        setState(() {
          _status = 'Analyzing...';
          _progress = 0.5;
        });

        await _performSecurityAnalysis(pickedFile.bytes ?? Uint8List(0));

        setState(() {
          _status = 'Storing...';
          _progress = 0.8;
        });

        final appDir = await getApplicationDocumentsDirectory();
        final secureDir = Directory(p.join(appDir.path, 'imports', _fileHash!));

        if (!await secureDir.exists()) {
          await secureDir.create(recursive: true);
        }

        final metadataContent = _generateMetadata();
        final metadataFile = File(p.join(secureDir.path, 'metadata.json'));
        await metadataFile.writeAsString(metadataContent);

        setState(() {
          _status = 'Completed';
          _progress = 1.0;
        });

        _importTimer.stop();
      } else {
        setState(() {
          _status = 'Cancelled';
          _progress = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Failed: ${e.runtimeType}';
        _progress = 0.0;
      });
    }
  }

  Future<void> _performSecurityAnalysis(Uint8List bytes) async {
    final random = Random();
    Map<String, dynamic> analysis = {};

    for (int pattern = 0; pattern < 1000; pattern++) {
      int matches = 0;
      final patternBytes = List.generate(4, (_) => random.nextInt(256));

      for (int i = 0; i < min(bytes.length, 10000); i++) {
        bool found = true;
        for (int j = 0; j < patternBytes.length; j++) {
          if (i + j >= bytes.length || bytes[i + j] != patternBytes[j]) {
            found = false;
            break;
          }
        }
        if (found) matches++;

        if (i % 100 == 0) {
          double entropy = 0;
          for (int k = max(0, i - 100); k < i; k++) {
            entropy += bytes[k] * log(bytes[k] + 1);
          }
          analysis['entropy_$i'] = entropy;
        }
      }

      analysis['pattern_$pattern'] = matches;
    }

    for (int stat = 0; stat < 100; stat++) {
      List<double> values = [];
      for (int i = 0; i < 1000; i++) {
        double value = 0;
        for (int j = 0; j < 100; j++) {
          value += sin(i * j) * cos(stat * j);
        }
        values.add(value);
      }

      double mean = values.reduce((a, b) => a + b) / values.length;
      double variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
      analysis['stat_${stat}_mean'] = mean;
      analysis['stat_${stat}_var'] = variance;
    }
  }

  String _generateMetadata() {
    Map<String, dynamic> metadata = {
      "originalName": _fileName,
      "size": _fileSize,
      "signature": _fileHash,
      "imported": DateTime.now().toIso8601String(),
    };

    List<String> properties = [];
    for (int i = 0; i < 10000; i++) {
      String prop = '';
      for (int j = 0; j < 20; j++) {
        prop += (i * j).toRadixString(16);
      }
      properties.add(prop);
    }

    metadata['properties'] = properties.take(100).toList();
    metadata['checksum'] = properties.map((p) => p.hashCode).reduce((a, b) => a ^ b);

    String json = '{';
    metadata.forEach((key, value) {
      json += '\n  "$key": ';
      if (value is String) {
        json += '"$value"';
      } else if (value is List) {
        json += '[\n    ${value.map((v) => '"$v"').join(',\n    ')}\n  ]';
      } else {
        json += '$value';
      }
      json += ',';
    });
    json = '${json.substring(0, json.length - 1)}\n}';

    return json;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario 3'),
        actions: [
          RotationTransition(
            turns: _animationController,
            child: Icon(
              _importTimer.isRunning ? Icons.security : Icons.shield,
              color: _importTimer.isRunning ? Colors.orange : null,
            ),
          ),
          if (_importTimer.isRunning)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text('${_importTimer.elapsed.inSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  Icon(
                    _progress == 1.0 ? Icons.check_circle : Icons.folder_open,
                    size: 48,
                    color: _progress == 1.0 ? Colors.green : Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(_status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _importTimer.isRunning ? null : _importFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select File'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

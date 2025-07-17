import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For compute()
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Page3 extends StatefulWidget {
  const Page3({super.key});

  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> with SingleTickerProviderStateMixin {
  String _status = 'Ready'; // Status text shown in UI
  double _progress = 0.0; // Progress value for circular progress indicator

  String? _fileName;
  int? _fileSize;
  String? _fileHash;

  final Stopwatch _importTimer = Stopwatch(); // Measures import duration
  late AnimationController _animationController; // Spins icon during processing

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(seconds: 1), vsync: this)
      ..repeat(); // Infinite rotation animation
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Validates that the file exists and has a non-zero checksum
  Future<bool> _validateFileIntegrity(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final stat = await file.stat();
      if (stat.size > 100 * 1024 * 1024) return false; // Limit to 100MB

      final bytes = await file.readAsBytes();
      int checksum = 0;

      // Simple XOR checksum for quick validation
      for (int i = 0; i < min(bytes.length, 100000); i++) {
        checksum ^= (bytes[i] << (i % 8));
        checksum = (checksum * 31) & 0xFFFFFFFF;
      }

      return checksum != 0;
    } catch (_) {
      return false;
    }
  }

  // Runs the signature computation in a background isolate using compute()
  Future<String> _generateFileSignatureAsync(String filePath, Uint8List? fileBytes) async {
    return await compute(_computeSignature, {'path': filePath, 'bytes': fileBytes});
  }

  // Signature generation function that will run off the main thread
  static String _computeSignature(Map<String, dynamic> args) {
    final filePath = args['path'] as String;
    final fileBytes = args['bytes'] as Uint8List?;

    int pathSignature = 0;
    final pathSegments = filePath.split(Platform.pathSeparator);
    final hashComponents = <int>[];

    // Lightened path hashing loop
    for (int i = 0; i < 200000; i++) {
      final segment = pathSegments[i % pathSegments.length];

      for (int j = 0; j < segment.length; j++) {
        pathSignature += segment.codeUnitAt(j) * (i + 1) * (j + 1);
        pathSignature ^= (pathSignature << 5) | (pathSignature >> 27);
      }

      if (i % 5000 == 0) {
        hashComponents.add(pathSignature);
      }
    }

    // Add file content to signature (if present)
    if (fileBytes != null && fileBytes.isNotEmpty) {
      int contentSignature = 0;
      final sampleSize = min(fileBytes.length, 5000);

      for (int i = 0; i < sampleSize; i++) {
        contentSignature ^= fileBytes[i] << (i % 8);
        contentSignature = (contentSignature * 37) & 0xFFFFFFFF;
      }

      pathSignature ^= contentSignature;
    }

    return '0x${pathSignature.toRadixString(16).toUpperCase()}';
  }

  // Main file import flow
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
          setState(() => _status = 'Error: No path');
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
          setState(() => _status = 'Validation failed');
          return;
        }

        setState(() {
          _status = 'Generating signature...';
          _progress = 0.3;
        });

        // Run heavy signature computation in background
        final signature = await _generateFileSignatureAsync(pickedFile.path!, pickedFile.bytes);
        _fileHash = signature;

        setState(() {
          _status = 'Analyzing...';
          _progress = 0.5;
        });

        // Simulate light async analysis to keep UI responsive
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() {
          _status = 'Storing...';
          _progress = 0.8;
        });

        // Store metadata in app directory
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

  // Simple JSON-like metadata generation
  String _generateMetadata() {
    Map<String, dynamic> metadata = {
      "originalName": _fileName,
      "size": _fileSize,
      "signature": _fileHash,
      "imported": DateTime.now().toIso8601String(),
    };

    metadata['checksum'] = metadata.toString().hashCode;

    String json = '{';
    metadata.forEach((key, value) {
      json += '\n  "$key": ';
      json += value is String ? '"$value",' : '$value,';
    });
    json = '${json.substring(0, json.length - 1)}\n}';

    return json;
  }

  // UI with progress, animation, and button
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

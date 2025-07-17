import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:shift_handover_challenge/core/error/app_error.dart';
import 'package:shift_handover_challenge/features/shift_handover/data/in_memory_shift_repository.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';
import 'package:shift_handover_challenge/features/shift_handover/service/shift_handover_service.dart';

class ShiftHandoverServiceImpl implements ShiftHandoverService {
  final InMemoryShiftRepository store;
  final bool Function() randomBool;

  const ShiftHandoverServiceImpl(
    this.store, {
    this.randomBool = _defaultRandomBool,
  });

  static bool _defaultRandomBool() => Random().nextBool();

  @override
  AppErrorOr<ShiftReport> getShiftReport(String caregiverId) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final res = await store.fetchReport(caregiverId);
      if (res != null) return Right(res);
      final data = ShiftReport(
        id: 'shift-123',
        caregiverId: caregiverId,
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        notes: List.generate(5, (index) {
          final type =
              NoteType.values[Random().nextInt(NoteType.values.length)];
          return HandoverNote(
            id: 'note-$index',
            text: 'This is a sample note of type ${type.name}.',
            type: type,
            timestamp: DateTime.now().subtract(Duration(hours: index)),
            authorId: 'caregiver-A',
          );
        }),
      );
      return Right(data);
    } catch (e) {
      return Left(AppError(e.toString()));
    }
  }

  @override
  AppErrorOr<bool> submitShiftReport(ShiftReport report) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (randomBool()) {
        print(
            'Report submitted successfully for caregiver ${report.caregiverId}');
        await store.submitReport(report);
        return const Right(true);
      } else {
        print('Failed to submit report for caregiver ${report.caregiverId}');
        throw Exception('Network error: Failed to submit report.');
      }
    } on Exception catch (e) {
      return Left(AppError(e.toString()));
    }
  }

  @override
  AppErrorOr<Unit> addNewNote(
    HandoverNote note,
    String reportId,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      await store.addNote(reportId, note);
      return const Right(unit);
    } catch (e) {
      return Left(AppError(e.toString()));
    }
  }
}

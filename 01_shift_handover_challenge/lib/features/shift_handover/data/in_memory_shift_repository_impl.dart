// lib/features/shift_handover/data/in_memory_shift_repository.dart

import 'package:shift_handover_challenge/features/shift_handover/data/in_memory_shift_repository.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';

class InMemoryShiftRepositoryImpl implements InMemoryShiftRepository {
  final Map<String, ShiftReport> _reports = {};

  @override
  Future<ShiftReport?> fetchReport(String reportId) async {
    print(_reports);
    return _reports[reportId];
  }

  @override
  Future<void> addNote(String reportId, HandoverNote note) async {
    final report = _reports[reportId];
    if (report != null) {
      final updatedNotes = [...report.notes, note];
      final updatedReport = report.copyWith(notes: updatedNotes);
      _reports[reportId] = updatedReport;
    }
    print(_reports);
  }

  @override
  Future<void> updateNote(String reportId, HandoverNote updatedNote) async {
    final report = _reports[reportId];
    if (report != null) {
      final index = report.notes.indexWhere((n) => n.id == updatedNote.id);
      if (index != -1) {
        report.notes[index] = updatedNote;
      }
    }
  }

  @override
  Future<void> deleteNote(String reportId, String noteId) async {
    final report = _reports[reportId];
    report?.notes.removeWhere((note) => note.id == noteId);
  }

  @override
  Future<void> submitReport(ShiftReport report) async {
    print(_reports);
    _reports[report.caregiverId] = report;
  }
}

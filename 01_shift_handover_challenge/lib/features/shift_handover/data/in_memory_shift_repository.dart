import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';

abstract class InMemoryShiftRepository {
  Future<ShiftReport?> fetchReport(String caregiverId);
  Future<void> addNote(String reportId, HandoverNote note);
  Future<void> updateNote(String reportId, HandoverNote updatedNote);
  Future<void> deleteNote(String reportId, String noteId);
  Future<void> submitReport(ShiftReport report);
}

import 'package:mockito/mockito.dart';
import 'package:shift_handover_challenge/features/shift_handover/data/in_memory_shift_repository.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';

class MockInMemoryShiftRepository extends Mock
    implements InMemoryShiftRepository {
  @override
  Future<ShiftReport?> fetchReport(String reportId) {
    // Use noSuchMethod to handle unstubbed calls and specify the return type
    return super.noSuchMethod(
      Invocation.method(#fetchReport, [reportId]),
      returnValue: Future<ShiftReport?>.value(null),
      returnValueForMissingStub: Future<ShiftReport?>.value(null),
    ) as Future<ShiftReport?>;
  }

  @override
  Future<void> submitReport(ShiftReport report) {
    return super.noSuchMethod(
      Invocation.method(#submitReport, [report]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    ) as Future<void>;
  }

  @override
  Future<void> addNote(String reportId, HandoverNote note) {
    return super.noSuchMethod(
      Invocation.method(#addNote, [reportId, note]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    ) as Future<void>;
  }

  // Add other overridden methods similarly if you stub them
}

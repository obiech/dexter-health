import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';
import 'package:shift_handover_challenge/features/shift_handover/service/shift_handover_service_impl.dart';

import '../../../mocks/in_memory_shift_mocks.dart';

void main() {
  late MockInMemoryShiftRepository mockRepository;
  late ShiftHandoverServiceImpl service;

  group('getShiftReport', () {
    const caregiverId = 'caregiver-1';
    setUpAll(() {
      mockRepository = MockInMemoryShiftRepository();
      service = ShiftHandoverServiceImpl(
        mockRepository,
        // Inject fixed randomBool for deterministic tests
        randomBool: () => true,
      );
    });

    test('returns report from repository when found', () async {
      final report = ShiftReport(
        id: 'shift-1',
        caregiverId: caregiverId,
        startTime: DateTime.now(),
        notes: [],
      );

      when(mockRepository.fetchReport(caregiverId))
          .thenAnswer((_) => Future.value(report));

      final result = await service.getShiftReport(caregiverId);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw Exception()),
          isA<ShiftReport>().having((r) => r.id, 'id', 'shift-1'));
    });

    test('returns Left(AppError) on exception', () async {
      when(mockRepository.fetchReport(caregiverId))
          .thenThrow(Exception('fail'));

      final result = await service.getShiftReport(caregiverId);

      expect(result.isLeft(), true);
    });
  });

  group('submitShiftReport', () {
    final report = ShiftReport(
      id: 'shift-123',
      caregiverId: 'caregiver-1',
      startTime: DateTime.now(),
      notes: [],
    );

    test('returns Right(true) when randomBool returns true and submit succeeds',
        () async {
      when(mockRepository.submitReport(report))
          .thenAnswer((_) async => Future.value());

      final result = await service.submitShiftReport(report);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => false), true);
      verify(mockRepository.submitReport(report)).called(1);
    });

    test(
        'returns Left(AppError) when randomBool returns false (simulate failure)',
        () async {
      // Override service with randomBool always false
      service = ShiftHandoverServiceImpl(
        mockRepository,
        randomBool: () => false,
      );

      final result = await service.submitShiftReport(report);

      expect(result.isLeft(), true);
    });

    test('returns Left(AppError) when submitReport throws', () async {
      when(mockRepository.submitReport(report))
          .thenThrow(Exception('failed to submit'));

      final result = await service.submitShiftReport(report);

      expect(result.isLeft(), true);
    });
  });

  group('addNewNote', () {
    final note = HandoverNote(
      id: 'note-1',
      text: 'Test note',
      type: NoteType.task,
      timestamp: DateTime.now(),
      authorId: 'author-1',
    );
    const reportId = 'report-1';

    test('returns Right(unit) when addNote succeeds', () async {
      when(mockRepository.addNote(reportId, note)).thenAnswer((_) async {});

      final result = await service.addNewNote(note, reportId);

      expect(result.isRight(), true);
      verify(mockRepository.addNote(reportId, note)).called(1);
    });

    test('returns Left(AppError) when addNote throws', () async {
      when(mockRepository.addNote(reportId, note))
          .thenThrow(Exception('failed to add note'));

      final result = await service.addNewNote(note, reportId);

      expect(result.isLeft(), true);
    });
  });
}

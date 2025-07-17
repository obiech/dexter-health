import 'package:flutter_test/flutter_test.dart';
import 'package:shift_handover_challenge/features/shift_handover/data/in_memory_shift_repository_impl.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';

void main() {
  late InMemoryShiftRepositoryImpl repository;

  setUp(() {
    repository = InMemoryShiftRepositoryImpl();
  });

  group('InMemoryShiftRepositoryImpl', () {
    const reportId = 'report-1';
    const caregiverId = 'caregiver-1';

    final initialReport = ShiftReport(
      id: reportId,
      caregiverId: caregiverId,
      startTime: DateTime.now(),
      notes: [],
    );

    test('fetchReport returns null when no report exists', () async {
      final fetched = await repository.fetchReport(reportId);
      expect(fetched, isNull);
    });

    test('submitReport adds a new report', () async {
      await repository.submitReport(initialReport);

      final fetched = await repository.fetchReport(caregiverId);
      expect(fetched, isNotNull);
      expect(fetched!.id, reportId);
      expect(fetched.caregiverId, caregiverId);
      expect(fetched.notes, isEmpty);
    });

    test('addNote adds note to existing report', () async {
      await repository.submitReport(initialReport);

      final note = HandoverNote(
        id: 'note-1',
        text: 'Test note',
        type: NoteType.task,
        timestamp: DateTime.now(),
        authorId: 'author-1',
      );

      await repository.addNote(caregiverId, note);

      final fetched = await repository.fetchReport(caregiverId);
      expect(fetched, isNotNull);
      expect(fetched!.notes.length, 1);
      expect(fetched.notes.first.id, 'note-1');
    });

    test('updateNote updates an existing note', () async {
      final note = HandoverNote(
        id: 'note-1',
        text: 'Original note',
        type: NoteType.task,
        timestamp: DateTime.now(),
        authorId: 'author-1',
      );

      final reportWithNote = initialReport.copyWith(notes: [note]);
      await repository.submitReport(reportWithNote);

      final updatedNote = note.copyWith(text: 'Updated note');

      await repository.updateNote(caregiverId, updatedNote);

      final fetched = await repository.fetchReport(caregiverId);
      expect(fetched, isNotNull);
      expect(fetched!.notes.length, 1);
      expect(fetched.notes.first.text, 'Updated note');
    });

    test('deleteNote removes the note from report', () async {
      final note1 = HandoverNote(
        id: 'note-1',
        text: 'Note 1',
        type: NoteType.task,
        timestamp: DateTime.now(),
        authorId: 'author-1',
      );
      final note2 = HandoverNote(
        id: 'note-2',
        text: 'Note 2',
        type: NoteType.observation,
        timestamp: DateTime.now(),
        authorId: 'author-1',
      );

      final reportWithNotes = initialReport.copyWith(notes: [note1, note2]);
      await repository.submitReport(reportWithNotes);

      await repository.deleteNote(caregiverId, 'note-1');

      final fetched = await repository.fetchReport(caregiverId);
      expect(fetched, isNotNull);
      expect(fetched!.notes.length, 1);
      expect(fetched.notes.first.id, 'note-2');
    });
  });
}

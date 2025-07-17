import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';
import 'package:shift_handover_challenge/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Shift Handover screen loads and adds a note',
      (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle();

    // Check that loading indicator appears
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for loading to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Check that we are on the ShiftHandoverScreen
    expect(find.text('Add Note'), findsOneWidget);

    // Enter text into the note field
    final noteField = find.byType(TextFormField);
    await tester.enterText(noteField, 'Integration test note');
    await tester.pump();

    // Select a note type if dropdown is available
    final dropdown = find.byType(DropdownButton<NoteType>);
    if (dropdown.evaluate().isNotEmpty) {
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('task').last);
      await tester.pump();
    }

    // Tap "Add Note" button
    final addNoteButton = find.widgetWithText(ElevatedButton, 'Add Note');
    await tester.tap(addNoteButton);
    await tester.pumpAndSettle();

    // Expect the note to be added to the list
    expect(find.text('Integration test note'), findsOneWidget);
  });
}

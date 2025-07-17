part of '../shift_handover_screen.dart';

class _NotesList extends StatelessWidget {
  const _NotesList({required this.notes});
  final List<HandoverNote> notes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return NoteCard(note: notes[index]);
      },
    );
  }
}

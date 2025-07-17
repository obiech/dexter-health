part of '../note_card.dart';

class NoteCardContent extends StatelessWidget {
  final HandoverNote note;
  final Color color;

  const NoteCardContent({super.key, required this.note, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 8),
        NoteCardMeta(note: note, color: color),
      ],
    );
  }
}

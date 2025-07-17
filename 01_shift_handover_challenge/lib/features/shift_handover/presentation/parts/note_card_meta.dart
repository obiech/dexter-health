part of '../note_card.dart';

class NoteCardMeta extends StatelessWidget {
  final HandoverNote note;
  final Color color;

  const NoteCardMeta({super.key, required this.note, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            note.type.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Text(
          DateFormat.jm().format(note.timestamp),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}

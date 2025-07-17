part of '../shift_handover_screen.dart';

class _EmptyNoteMessage extends StatelessWidget {
  const _EmptyNoteMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No notes added yet.\nUse the form below to add the first note.',
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}

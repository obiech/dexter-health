part of '../shift_handover_screen.dart';

class _NoteTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  const _NoteTextField({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Add a new note for the next shift...',
      ),
      onSubmitted: onSubmitted,
    );
  }
}

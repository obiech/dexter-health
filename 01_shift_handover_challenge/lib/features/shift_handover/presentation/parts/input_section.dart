part of '../shift_handover_screen.dart';

class _InputSection extends StatefulWidget {
  final ShiftHandoverState state;

  const _InputSection({required this.state});

  @override
  State<_InputSection> createState() => _InputSectionState();
}

class _InputSectionState extends State<_InputSection> {
  final TextEditingController _textController = TextEditingController();
  NoteType _selectedType = NoteType.observation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NoteTextField(
              controller: _textController,
              onSubmitted: _handleNoteSubmit,
            ),
            const SizedBox(height: 12),
            NoteTypeDropdown(
              selectedType: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 16),
            SubmitReportButton(
              isSubmitting: widget.state.isSubmitting,
              onPressed: () => _showSubmitDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNoteSubmit(String value) {
    if (value.isNotEmpty) {
      context.read<ShiftHandoverBloc>().add(AddNewNote(value, _selectedType));
      _textController.clear();
    }
  }

  void _showSubmitDialog(BuildContext context) {
    final summaryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalize and Submit Report'),
        content: TextField(
          controller: summaryController,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: "Enter a brief shift summary..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<ShiftHandoverBloc>()
                  .add(SubmitReport(summaryController.text));
              Navigator.pop(dialogContext);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

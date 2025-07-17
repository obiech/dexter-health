import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';

part 'parts/note_card_contents.dart';
part 'parts/note_card_icon.dart';
part 'parts/note_card_meta.dart';

class NoteCard extends StatelessWidget {
  final HandoverNote note;

  const NoteCard({super.key, required this.note});

  static const Map<NoteType, IconData> _iconMap = {
    NoteType.observation: Icons.visibility_outlined,
    NoteType.incident: Icons.warning_amber_rounded,
    NoteType.medication: Icons.medical_services_outlined,
    NoteType.task: Icons.check_circle_outline,
    NoteType.supplyRequest: Icons.shopping_cart_checkout_outlined,
  };

  static final Map<NoteType, Color> _colorMap = {
    NoteType.observation: Colors.blue.shade700,
    NoteType.incident: Colors.red.shade700,
    NoteType.medication: Colors.purple.shade700,
    NoteType.task: Colors.green.shade700,
    NoteType.supplyRequest: Colors.orange.shade700,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colorMap[note.type] ?? Colors.grey;
    final icon = _iconMap[note.type] ?? Icons.help_outline;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NoteCardIcon(icon: icon, color: color),
            Expanded(
              child: NoteCardContent(note: note, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

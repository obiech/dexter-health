part of '../note_card.dart';

class NoteCardIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const NoteCardIcon({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0, top: 4.0),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

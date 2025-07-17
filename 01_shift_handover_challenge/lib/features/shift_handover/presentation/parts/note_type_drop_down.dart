part of '../shift_handover_screen.dart';

class NoteTypeDropdown extends StatelessWidget {
  final NoteType selectedType;
  final ValueChanged<NoteType> onChanged;

  const NoteTypeDropdown({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFBDBDBD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<NoteType>(
          value: selectedType,
          isExpanded: true,
          icon: const Icon(Icons.category_outlined),
          onChanged: (NoteType? newValue) {
            if (newValue != null) onChanged(newValue);
          },
          items: NoteType.values
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

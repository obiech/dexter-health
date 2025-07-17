part of 'shift_handover_bloc.dart';

sealed class ShiftHandoverEvent extends Equatable {
  const ShiftHandoverEvent();
  @override
  List<Object> get props => [];
}

class LoadShiftReport extends ShiftHandoverEvent {
  final String caregiverId;
  const LoadShiftReport(this.caregiverId);
}

class AddNewNote extends ShiftHandoverEvent {
  final String text;
  final NoteType type;
  const AddNewNote(this.text, this.type);
}

class SubmitReport extends ShiftHandoverEvent {
  final String summary;
  const SubmitReport(this.summary);
}

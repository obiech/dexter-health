import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';
import 'package:shift_handover_challenge/features/shift_handover/service/shift_handover_service.dart';

part 'shift_handover_event.dart';
part 'shift_handover_state.dart';

class ShiftHandoverBloc extends Bloc<ShiftHandoverEvent, ShiftHandoverState> {
  final ShiftHandoverService service;

  ShiftHandoverBloc(this.service) : super(const ShiftHandoverState()) {
    on<LoadShiftReport>(_onLoadShiftReport);
    on<AddNewNote>(_onAddNewNote);
    on<SubmitReport>(_onSubmitReport);
  }

  Future<void> _onLoadShiftReport(
    LoadShiftReport event,
    Emitter<ShiftHandoverState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final report = await service.getShiftReport(event.caregiverId);
    report.fold(
      (l) => emit(state.copyWith(error: l.message, isLoading: false)),
      (r) => emit(state.copyWith(report: r, isLoading: false)),
    );
  }

  void _onAddNewNote(
    AddNewNote event,
    Emitter<ShiftHandoverState> emit,
  ) async {
    if (state.report == null) return;

    final newNote = HandoverNote(
      id: 'note-${Random().nextInt(1000)}',
      text: event.text,
      type: event.type,
      timestamp: DateTime.now(),
      authorId: state.report!.caregiverId,
    );

    final updatedNotes = List<HandoverNote>.from(state.report!.notes)
      ..add(newNote);
    final updatedReport = ShiftReport(
      id: state.report!.id,
      caregiverId: state.report!.caregiverId,
      startTime: state.report!.startTime,
      notes: updatedNotes,
    );

    await service.addNewNote(newNote, state.report!.caregiverId);

    emit(state.copyWith(report: updatedReport));
  }

  Future<void> _onSubmitReport(
    SubmitReport event,
    Emitter<ShiftHandoverState> emit,
  ) async {
    if (state.report == null) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final updatedReport = state.report!;
    updatedReport.submitReport(event.summary);

    final res = await service.submitShiftReport(updatedReport);

    res.fold(
      (l) => emit(
        state.copyWith(error: 'Failed to submit report', isSubmitting: false),
      ),
      (r) => emit(state.copyWith(report: updatedReport, isSubmitting: false)),
    );
  }
}

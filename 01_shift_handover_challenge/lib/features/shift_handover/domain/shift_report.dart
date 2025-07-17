import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show immutable;
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';

@immutable
class ShiftReport extends Equatable {
  final String id;
  final String caregiverId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<HandoverNote> notes;
  final String summary;
  final bool isSubmitted;

  const ShiftReport({
    required this.id,
    required this.caregiverId,
    required this.startTime,
    this.endTime,
    this.notes = const [],
    this.summary = '',
    this.isSubmitted = false,
  });

  /// Returns a new [ShiftReport] with the new note added.
  ShiftReport addNote(HandoverNote note) {
    return copyWith(notes: [...notes, note]);
  }

  /// Returns a new [ShiftReport] marked as submitted.
  ShiftReport submitReport(String summary) {
    return copyWith(
      summary: summary,
      endTime: DateTime.now(),
      isSubmitted: true,
    );
  }

  /// Useful for making modified copies
  ShiftReport copyWith({
    String? id,
    String? caregiverId,
    DateTime? startTime,
    DateTime? endTime,
    List<HandoverNote>? notes,
    String? summary,
    bool? isSubmitted,
  }) {
    return ShiftReport(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      summary: summary ?? this.summary,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        caregiverId,
        startTime,
        endTime,
        notes,
        summary,
        isSubmitted,
      ];
}

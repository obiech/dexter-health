import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';

@immutable
class HandoverNote extends Equatable {
  final String id;
  final String text;
  final NoteType type;
  final DateTime timestamp;
  final String authorId;
  final List<String> taggedResidentIds;
  final bool isAcknowledged;

  const HandoverNote({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.authorId,
    this.taggedResidentIds = const [],
    this.isAcknowledged = false,
  });

  /// Returns a new HandoverNote marked as acknowledged
  HandoverNote acknowledge() {
    return copyWith(isAcknowledged: true);
  }

  /// Returns a modified copy
  HandoverNote copyWith({
    String? id,
    String? text,
    NoteType? type,
    DateTime? timestamp,
    String? authorId,
    List<String>? taggedResidentIds,
    bool? isAcknowledged,
  }) {
    return HandoverNote(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      authorId: authorId ?? this.authorId,
      taggedResidentIds: taggedResidentIds ?? this.taggedResidentIds,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  /// Returns the background color associated with the note type
  Color getColor() {
    switch (type) {
      case NoteType.incident:
        return Colors.red.shade100;
      case NoteType.supplyRequest:
        return Colors.yellow.shade100;
      case NoteType.observation:
      default:
        return Colors.blue.shade100;
    }
  }

  @override
  List<Object?> get props => [
        id,
        text,
        type,
        timestamp,
        authorId,
        taggedResidentIds,
        isAcknowledged,
      ];
}

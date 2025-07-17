import 'package:dartz/dartz.dart';
import 'package:shift_handover_challenge/core/error/app_error.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/shift_report.dart';

abstract class ShiftHandoverService {
  AppErrorOr<ShiftReport> getShiftReport(String caregiverId);

  AppErrorOr<bool> submitShiftReport(ShiftReport report);
  AppErrorOr<Unit> addNewNote(HandoverNote note, String caregiverId);
}

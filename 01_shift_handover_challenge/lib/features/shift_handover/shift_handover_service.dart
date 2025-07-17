// import 'dart:math';

// import 'shift_handover_models.dart';

// class ShiftHandoverService {
//   Future<ShiftReport> getShiftReport(String caregiverId) async {
//     await Future.delayed(const Duration(seconds: 1));
//     return ShiftReport(
//       id: 'shift-123',
//       caregiverId: caregiverId,
//       startTime: DateTime.now().subtract(const Duration(hours: 8)),
//       notes: List.generate(5, (index) {
//         final type = NoteType.values[Random().nextInt(NoteType.values.length)];
//         return HandoverNote(
//           id: 'note-$index',
//           text: 'This is a sample note of type ${type.name}.',
//           type: type,
//           timestamp: DateTime.now().subtract(Duration(hours: index)),
//           authorId: 'caregiver-A',
//         );
//       }),
//     );
//   }

//   Future<bool> submitShiftReport(ShiftReport report) async {
//     await Future.delayed(const Duration(seconds: 2));
    
//     if (Random().nextBool()) {
//       print('Report submitted successfully for caregiver ${report.caregiverId}');
//       return true;
//     } else {
//       print('Failed to submit report for caregiver ${report.caregiverId}');
//       throw Exception('Network error: Failed to submit report.');
//     }
//   }
// } 

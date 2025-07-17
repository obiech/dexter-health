// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:shift_handover_challenge/features/shift_handover/note_card.dart';
// import 'package:shift_handover_challenge/features/shift_handover/shift_handover_bloc.dart';
// import 'package:shift_handover_challenge/features/shift_handover/shift_handover_models.dart';

// class ShiftHandoverScreen extends StatelessWidget {
//   const ShiftHandoverScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => ShiftHandoverBloc()..add(const LoadShiftReport('current-user-id')),
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Shift Handover Report'),
//           elevation: 0,
//           actions: [
//             BlocBuilder<ShiftHandoverBloc, ShiftHandoverState>(
//               builder: (context, state) {
//                 if (state.isLoading && state.report == null) return const SizedBox.shrink();
//                 return IconButton(
//                   icon: const Icon(Icons.refresh),
//                   tooltip: 'Refresh Report',
//                   onPressed: () {
//                     context.read<ShiftHandoverBloc>().add(const LoadShiftReport('current-user-id'));
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//         body: BlocConsumer<ShiftHandoverBloc, ShiftHandoverState>(
//           listener: (context, state) {
//             if (state.error != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('An error occurred: ${state.error}'),
//                   backgroundColor: Theme.of(context).colorScheme.error,
//                 ),
//               );
//             }
//             if (state.report?.isSubmitted ?? false) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: const Text('Report submitted successfully!'),
//                   backgroundColor: Theme.of(context).colorScheme.secondary,
//                 ),
//               );
//             }
//           },
//           builder: (context, state) {
//             if (state.isLoading && state.report == null) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (state.report == null) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('Failed to load shift report.', style: TextStyle(fontSize: 16)),
//                     const SizedBox(height: 16),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Try Again'),
//                       onPressed: () => context.read<ShiftHandoverBloc>().add(const LoadShiftReport('current-user-id')),
//                     )
//                   ],
//                 ),
//               );
//             }

//             final report = state.report!;

//             return Column(
//               children: [
//                 if (report.notes.isEmpty)
//                   Expanded(
//                     child: Center(
//                       child: Text(
//                         'No notes added yet.\nUse the form below to add the first note.',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
//                       ),
//                     ),
//                   )
//                 else
//                   Expanded(
//                     child: ListView.separated(
//                       padding: const EdgeInsets.all(16.0),
//                       itemCount: report.notes.length,
//                       separatorBuilder: (context, index) => const SizedBox(height: 12),
//                       itemBuilder: (context, index) {
//                         return NoteCard(note: report.notes[index]);
//                       },
//                     ),
//                   ),
//                 _buildInputSection(context, state),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildInputSection(BuildContext context, ShiftHandoverState state) {
//     final textController = TextEditingController();
//     NoteType selectedType = NoteType.observation;

//     return Material(
//       elevation: 8.0,
//       child: Container(
//         padding: const EdgeInsets.all(16.0),
//         color: Colors.white,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             StatefulBuilder(builder: (context, setState) {
//               return Column(
//                 children: [
//                   TextField(
//                     controller: textController,
//                     decoration: const InputDecoration(
//                       hintText: 'Add a new note for the next shift...',
//                     ),
//                     onSubmitted: (value) {
//                       if (value.isNotEmpty) {
//                         context.read<ShiftHandoverBloc>().add(AddNewNote(value, selectedType));
//                         textController.clear();
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12.0),
//                       border: Border.all(color: const Color(0xFFBDBDBD)),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<NoteType>(
//                         value: selectedType,
//                         isExpanded: true,
//                         icon: const Icon(Icons.category_outlined),
//                         onChanged: (NoteType? newValue) {
//                           if (newValue != null) {
//                             setState(() {
//                               selectedType = newValue;
//                             });
//                           }
//                         },
//                         items: NoteType.values.map((NoteType type) {
//                           return DropdownMenuItem<NoteType>(
//                             value: type,
//                             child: Text(type.name.toUpperCase()),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             }),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               icon: state.isSubmitting ? const SizedBox.shrink() : const Icon(Icons.send),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 52),
//               ),
//               onPressed: state.isSubmitting
//                   ? null
//                   : () {
//                       _showSubmitDialog(context);
//                     },
//               label: state.isSubmitting
//                   ? const SizedBox(
//                       height: 24,
//                       width: 24,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 3,
//                         color: Colors.white,
//                       ))
//                   : const Text('Submit Final Report'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSubmitDialog(BuildContext context) {
//     final summaryController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Finalize and Submit Report'),
//         content: TextField(
//           controller: summaryController,
//           maxLines: 3,
//           decoration: const InputDecoration(hintText: "Enter a brief shift summary..."),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               context.read<ShiftHandoverBloc>().add(SubmitReport(summaryController.text));
//               Navigator.pop(dialogContext);
//             },
//             child: const Text('Submit'),
//           ),
//         ],
//       ),
//     );
//   }
// }

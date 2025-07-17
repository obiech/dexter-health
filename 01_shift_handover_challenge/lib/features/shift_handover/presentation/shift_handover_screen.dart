import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shift_handover_challenge/core/di/injection_container.dart'
    as di;
import 'package:shift_handover_challenge/features/shift_handover/bloc/shift_handover_bloc.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/handover_note.dart';
import 'package:shift_handover_challenge/features/shift_handover/domain/note_type.dart';
import 'package:shift_handover_challenge/features/shift_handover/presentation/note_card.dart';

part 'parts/app_bar.dart';
part 'parts/empty_note_widget.dart';
part 'parts/error_widget.dart';
part 'parts/input_section.dart';
part 'parts/note_list.dart';
part 'parts/note_text_field.dart';
part 'parts/note_type_drop_down.dart';
part 'parts/submit_report_button.dart';

class ShiftHandoverScreen extends StatelessWidget {
  const ShiftHandoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShiftHandoverBloc(di.sl())
        ..add(const LoadShiftReport('current-user-id')),
      child: const _ShiftHandoverView(),
    );
  }
}

class _ShiftHandoverView extends StatelessWidget {
  const _ShiftHandoverView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _CustomAppBar(),
      body: BlocConsumer<ShiftHandoverBloc, ShiftHandoverState>(
        listener: _handleBlocEvents,
        builder: (context, state) {
          if (state.isLoading && state.report == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.report == null) {
            return const _ErrorWidget();
          }

          return Column(
            children: [
              Expanded(
                child: state.report!.notes.isEmpty
                    ? const _EmptyNoteMessage()
                    : _NotesList(notes: state.report!.notes),
              ),
              _InputSection(state: state),
            ],
          );
        },
      ),
    );
  }

  void _handleBlocEvents(context, state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${state.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    if (state.report?.isSubmitted ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted successfully!'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }
}

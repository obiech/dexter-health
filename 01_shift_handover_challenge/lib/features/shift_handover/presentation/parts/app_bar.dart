part of '../shift_handover_screen.dart';

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Shift Handover Report'),
      elevation: 0,
      actions: [
        BlocBuilder<ShiftHandoverBloc, ShiftHandoverState>(
          builder: (context, state) {
            final isLoadingInitial = state.isLoading && state.report == null;
            if (isLoadingInitial) return const SizedBox.shrink();

            return IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Report',
              onPressed: () {
                context
                    .read<ShiftHandoverBloc>()
                    .add(const LoadShiftReport('current-user-id'));
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

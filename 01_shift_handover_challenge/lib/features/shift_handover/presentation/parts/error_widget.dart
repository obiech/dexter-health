part of '../shift_handover_screen.dart';

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Failed to load shift report.',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            onPressed: () => context
                .read<ShiftHandoverBloc>()
                .add(const LoadShiftReport('current-user-id')),
          )
        ],
      ),
    );
  }
}

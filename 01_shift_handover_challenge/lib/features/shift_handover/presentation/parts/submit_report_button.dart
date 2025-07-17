part of '../shift_handover_screen.dart';

class SubmitReportButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const SubmitReportButton({
    required this.isSubmitting,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: isSubmitting ? const SizedBox.shrink() : const Icon(Icons.send),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
      onPressed: isSubmitting ? null : onPressed,
      label: isSubmitting
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            )
          : const Text('Submit Final Report'),
    );
  }
}

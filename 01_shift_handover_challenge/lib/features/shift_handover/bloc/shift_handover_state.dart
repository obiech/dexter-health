part of 'shift_handover_bloc.dart';

final class ShiftHandoverState extends Equatable {
  final ShiftReport? report;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const ShiftHandoverState({
    this.report,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  ShiftHandoverState copyWith({
    ShiftReport? report,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return ShiftHandoverState(
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [report, isLoading, isSubmitting, error];
}

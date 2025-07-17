import 'package:get_it/get_it.dart';
import 'package:shift_handover_challenge/features/shift_handover/data/in_memory_shift_repository.dart';
import 'package:shift_handover_challenge/features/shift_handover/data/in_memory_shift_repository_impl.dart';
import 'package:shift_handover_challenge/features/shift_handover/service/shift_handover_service.dart';
import 'package:shift_handover_challenge/features/shift_handover/service/shift_handover_service_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl
    ..registerLazySingleton<InMemoryShiftRepository>(
        InMemoryShiftRepositoryImpl.new)
    ..registerLazySingleton<ShiftHandoverService>(
      () => ShiftHandoverServiceImpl(sl()),
    );
}

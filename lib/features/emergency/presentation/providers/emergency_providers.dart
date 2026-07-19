import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:medilink/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:medilink/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_timeline_event.dart';
import 'package:medilink/features/emergency/domain/repositories/emergency_repository.dart';

final emergencyRemoteDataSourceProvider = Provider<EmergencyRemoteDataSource>(
  (ref) => EmergencyRemoteDataSource(),
);

final emergencyLocalDataSourceProvider = Provider<EmergencyLocalDataSource>(
  (ref) => EmergencyLocalDataSource(),
);

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepositoryImpl(
    remote: ref.watch(emergencyRemoteDataSourceProvider),
    local: ref.watch(emergencyLocalDataSourceProvider),
  );
});

/// The request id of the emergency currently being tracked, if any. Set
/// right after `triggerSos` resolves, or restored on cold start from the
/// repository's local cache (see main.dart bootstrap).
final activeEmergencyIdProvider = StateProvider<String?>((ref) => null);

final watchEmergencyProvider =
    StreamProvider.autoDispose.family<EmergencyRequest, String>((ref, requestId) {
  return ref
      .watch(emergencyRepositoryProvider)
      .watchEmergency(requestId)
      .map((e) => e.match((f) => throw f, (r) => r));
});

final watchEmergencyTimelineProvider = StreamProvider.autoDispose
    .family<List<EmergencyTimelineEvent>, String>((ref, requestId) {
  return ref
      .watch(emergencyRepositoryProvider)
      .watchTimeline(requestId)
      .map((e) => e.match((f) => throw f, (r) => r));
});

/// Drives [SosConfirmScreen]'s trigger button: fires `triggerSos`, stores
/// the resulting request id in [activeEmergencyIdProvider] on success.
class SosController extends StateNotifier<AsyncValue<String?>> {
  SosController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> triggerSos({
    required EmergencyType type,
    required GeoPointValue location,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref.read(emergencyRepositoryProvider).triggerSos(
          type: type,
          location: location,
        );
    result.match(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (requestId) {
        _ref.read(activeEmergencyIdProvider.notifier).state = requestId;
        state = AsyncValue.data(requestId);
      },
    );
  }

  void reset() => state = const AsyncValue.data(null);
}

final sosControllerProvider =
    StateNotifierProvider<SosController, AsyncValue<String?>>(
  (ref) => SosController(ref),
);

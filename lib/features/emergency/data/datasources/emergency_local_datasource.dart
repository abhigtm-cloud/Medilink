import 'package:hive_flutter/hive_flutter.dart';
import 'package:medilink/features/emergency/data/models/emergency_request_model.dart';

/// Hive-backed cache of the active emergency request id, so if the app is
/// killed/reopened mid-emergency it can resume straight back into
/// [EmergencyTrackingScreen] before the network responds. See architecture
/// doc §8.
class EmergencyLocalDataSource {
  static const String _boxName = 'emergency_cache';
  static const String _activeRequestIdKey = 'active_request_id';
  static const String _lastKnownRequestKey = 'last_known_request';

  Future<Box> _openBox() => Hive.openBox(_boxName);

  Future<String?> getActiveRequestId() async {
    final box = await _openBox();
    return box.get(_activeRequestIdKey) as String?;
  }

  Future<void> setActiveRequestId(String? requestId) async {
    final box = await _openBox();
    if (requestId == null) {
      await box.delete(_activeRequestIdKey);
    } else {
      await box.put(_activeRequestIdKey, requestId);
    }
  }

  Future<void> cacheLastKnownRequest(EmergencyRequestModel request) async {
    final box = await _openBox();
    await box.put(_lastKnownRequestKey, request.toJson());
  }

  Future<EmergencyRequestModel?> getLastKnownRequest() async {
    final box = await _openBox();
    final json = box.get(_lastKnownRequestKey);
    if (json == null) return null;
    return EmergencyRequestModel.fromJson(Map<String, dynamic>.from(json as Map));
  }
}

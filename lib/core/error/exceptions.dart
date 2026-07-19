/// Thrown at the datasource layer, caught and mapped to a [Failure]
/// (see failures.dart) at the repository layer.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error']);
}

class PermissionException implements Exception {
  final String message;
  const PermissionException([this.message = 'Permission denied']);
}

class NoHospitalFoundException implements Exception {
  final String message;
  const NoHospitalFoundException([this.message = 'No hospital found']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}

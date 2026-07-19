/// Failures surfaced to the presentation layer. Repository implementations
/// map raw exceptions (Firebase, network, etc.) to these so no raw
/// [Exception]/[FirebaseException] ever escapes past the data layer.
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Please check your connection.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission to do that.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item could not be found.']);
}

class NoHospitalFoundFailure extends Failure {
  const NoHospitalFoundFailure([
    super.message = 'No hospital is currently reachable near your location.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}

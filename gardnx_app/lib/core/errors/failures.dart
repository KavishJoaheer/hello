/// Abstract base class for all domain-level failures in the GardNx
/// application.
///
/// Failures represent expected error conditions that the UI layer should
/// handle gracefully, as opposed to unrecoverable exceptions.
abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }

  @override
  int get hashCode => Object.hash(message, code);
}

/// Failure related to authentication operations (sign-in, sign-up, token).
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});

  factory AuthFailure.fromFirebaseCode(String firebaseCode) {
    switch (firebaseCode) {
      case 'user-not-found':
        return const AuthFailure(
          message: 'No account found with this email.',
          code: 'user-not-found',
        );
      case 'wrong-password':
        return const AuthFailure(
          message: 'Incorrect password. Please try again.',
          code: 'wrong-password',
        );
      case 'invalid-email':
        return const AuthFailure(
          message: 'The email address is not valid.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthFailure(
          message: 'This account has been disabled.',
          code: 'user-disabled',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          message: 'An account already exists with this email.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AuthFailure(
          message: 'The password is too weak. Use at least 6 characters.',
          code: 'weak-password',
        );
      case 'too-many-requests':
        return const AuthFailure(
          message: 'Too many attempts. Please try again later.',
          code: 'too-many-requests',
        );
      case 'invalid-credential':
        return const AuthFailure(
          message: 'Invalid email or password.',
          code: 'invalid-credential',
        );
      default:
        return AuthFailure(
          message: 'Authentication failed. Please try again.',
          code: firebaseCode,
        );
    }
  }

  factory AuthFailure.tokenExpired() {
    return const AuthFailure(
      message: 'Your session has expired. Please sign in again.',
      code: 'token-expired',
    );
  }
}

/// Failure related to network connectivity or HTTP errors.
class NetworkFailure extends Failure {
  final int? statusCode;

  const NetworkFailure({
    required super.message,
    this.statusCode,
    super.code,
  });

  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      message: 'No internet connection. Please check your network.',
      code: 'no-connection',
    );
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      message: 'Request timed out. Please try again.',
      code: 'timeout',
    );
  }

  factory NetworkFailure.serverError([int? statusCode]) {
    return NetworkFailure(
      message: 'Server error occurred. Please try again later.',
      statusCode: statusCode,
      code: 'server-error',
    );
  }

  factory NetworkFailure.fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return const NetworkFailure(
          message: 'Bad request. Please check your input.',
          statusCode: 400,
          code: 'bad-request',
        );
      case 401:
        return const NetworkFailure(
          message: 'Unauthorized. Please sign in again.',
          statusCode: 401,
          code: 'unauthorized',
        );
      case 403:
        return const NetworkFailure(
          message: 'Access denied.',
          statusCode: 403,
          code: 'forbidden',
        );
      case 404:
        return const NetworkFailure(
          message: 'Resource not found.',
          statusCode: 404,
          code: 'not-found',
        );
      case 429:
        return const NetworkFailure(
          message: 'Too many requests. Please slow down.',
          statusCode: 429,
          code: 'rate-limited',
        );
      default:
        if (statusCode >= 500) {
          return NetworkFailure.serverError(statusCode);
        }
        return NetworkFailure(
          message: 'Request failed with status $statusCode.',
          statusCode: statusCode,
          code: 'http-error',
        );
    }
  }
}

/// Failure related to garden image analysis or segmentation.
class AnalysisFailure extends Failure {
  const AnalysisFailure({required super.message, super.code});

  factory AnalysisFailure.uploadFailed() {
    return const AnalysisFailure(
      message: 'Failed to upload the garden photo. Please try again.',
      code: 'upload-failed',
    );
  }

  factory AnalysisFailure.segmentationFailed() {
    return const AnalysisFailure(
      message: 'Garden analysis failed. Please try a different photo.',
      code: 'segmentation-failed',
    );
  }

  factory AnalysisFailure.invalidImage() {
    return const AnalysisFailure(
      message: 'The selected image is not valid for analysis.',
      code: 'invalid-image',
    );
  }

  factory AnalysisFailure.imageTooLarge() {
    return const AnalysisFailure(
      message: 'Image is too large. Please select a smaller image.',
      code: 'image-too-large',
    );
  }
}

/// Failure related to input validation (forms, bed dimensions, etc.).
class ValidationFailure extends Failure {
  final String? fieldName;

  const ValidationFailure({
    required super.message,
    this.fieldName,
    super.code,
  });

  factory ValidationFailure.requiredField(String fieldName) {
    return ValidationFailure(
      message: '$fieldName is required.',
      fieldName: fieldName,
      code: 'required',
    );
  }

  factory ValidationFailure.invalidRange({
    required String fieldName,
    required double min,
    required double max,
  }) {
    return ValidationFailure(
      message: '$fieldName must be between $min and $max.',
      fieldName: fieldName,
      code: 'invalid-range',
    );
  }
}

/// Failure related to Firebase Storage or local file system operations.
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});

  factory StorageFailure.uploadFailed() {
    return const StorageFailure(
      message: 'Failed to upload file. Please try again.',
      code: 'upload-failed',
    );
  }

  factory StorageFailure.downloadFailed() {
    return const StorageFailure(
      message: 'Failed to download file.',
      code: 'download-failed',
    );
  }

  factory StorageFailure.deleteFailed() {
    return const StorageFailure(
      message: 'Failed to delete file.',
      code: 'delete-failed',
    );
  }

  factory StorageFailure.permissionDenied() {
    return const StorageFailure(
      message: 'Storage permission denied.',
      code: 'permission-denied',
    );
  }
}

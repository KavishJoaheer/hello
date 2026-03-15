/// Base exception class for all GardNx application errors.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when a network request fails.
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'NetworkException($statusCode, $code): $message';
}

/// Thrown when photo upload fails.
class UploadException extends AppException {
  const UploadException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Thrown when garden analysis / segmentation fails.
class AnalysisException extends AppException {
  const AnalysisException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Thrown when a required permission is denied.
class PermissionDeniedException extends AppException {
  final String permissionType;

  const PermissionDeniedException({
    required this.permissionType,
    required super.message,
    super.code,
  });
}

/// Thrown when Firestore operations fail.
class FirestoreException extends AppException {
  const FirestoreException({
    required super.message,
    super.code,
    super.originalError,
  });
}

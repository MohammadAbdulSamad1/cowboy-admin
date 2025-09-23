// app/utils/exceptions.dart

class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

// Common auth exceptions
class AuthExceptions {
  static const AuthException invalidEmail = AuthException(
    message: 'Please enter a valid email address.',
    code: 'invalid-email',
  );

  static const AuthException emptyEmail = AuthException(
    message: 'Email cannot be empty.',
    code: 'empty-email',
  );

  static const AuthException emptyPassword = AuthException(
    message: 'Password cannot be empty.',
    code: 'empty-password',
  );

  static const AuthException passwordTooShort = AuthException(
    message: 'Password must be at least 6 characters long.',
    code: 'password-too-short',
  );

  static const AuthException passwordsDoNotMatch = AuthException(
    message: 'Passwords do not match.',
    code: 'passwords-do-not-match',
  );

  static const AuthException invalidCredentials = AuthException(
    message: 'Invalid email or password. Please try again.',
    code: 'invalid-credentials',
  );

  static const AuthException userNotFound = AuthException(
    message: 'No account found with this email address.',
    code: 'user-not-found',
  );

  static const AuthException emailAlreadyExists = AuthException(
    message: 'An account with this email already exists.',
    code: 'email-already-exists',
  );

  static const AuthException networkError = AuthException(
    message: 'Network error. Please check your internet connection.',
    code: 'network-error',
  );

  static const AuthException serverError = AuthException(
    message: 'Server error. Please try again later.',
    code: 'server-error',
  );

  static const AuthException tooManyRequests = AuthException(
    message: 'Too many requests. Please try again later.',
    code: 'too-many-requests',
  );

  static const AuthException unknownError = AuthException(
    message: 'An unexpected error occurred. Please try again.',
    code: 'unknown-error',
  );

  static const AuthException noUser = AuthException(
    message: 'No user signed in.',
    code: 'no-user',
  );

  static const AuthException tokenExpired = AuthException(
    message: 'Your session has expired. Please sign in again.',
    code: 'token-expired',
  );

  static const AuthException invalidToken = AuthException(
    message: 'Invalid authentication token.',
    code: 'invalid-token',
  );

  static const AuthException accessDenied = AuthException(
    message: 'Access denied. You don\'t have permission.',
    code: 'access-denied',
  );

  static const AuthException validationError = AuthException(
    message: 'Invalid data provided.',
    code: 'validation-error',
  );
}
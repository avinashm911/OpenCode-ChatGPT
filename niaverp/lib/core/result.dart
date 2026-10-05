// NiAvERP core result/error model — Phase 00.
// No business policy is decided here. Every fallible application operation
// returns a [Result] carrying either a value or an [AppError] with a stable
// machine-readable code. Secrets must never be placed in [AppError.message].
// Traceability: AGENTS.md (Result/error model); strategy Slice 0.

/// Stable, machine-readable error carried by [Err].
class AppError {
  const AppError(this.code, this.message);

  /// Stable code, e.g. 'validation', 'not-found', 'conflict', 'locked'.
  final String code;

  /// Human-readable message. Must never contain key material or secrets.
  final String message;

  @override
  String toString() => 'AppError($code): $message';
}

/// Sealed result of a fallible operation.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

/// Successful result carrying [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

/// Failed result carrying [error].
final class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;
}

/// Convenience constructors.
Result<T> ok<T>(T value) => Ok<T>(value);
Result<T> err<T>(String code, String message) =>
    Err<T>(AppError(code, message));

/// Maps the value of an [Ok] through [f], passing [Err] through unchanged.
Result<U> mapResult<T, U>(Result<T> result, U Function(T) f) {
  return switch (result) {
    Ok<T>(:final value) => Ok<U>(f(value)),
    Err<T>(:final error) => Err<U>(error),
  };
}

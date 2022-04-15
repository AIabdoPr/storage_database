abstract class StorageDatabaseError implements Exception {
  const StorageDatabaseError([this.message]);

  final String? message;

  @override
  String toString() {
    String result = 'StorageDatabaseError';
    if (message is String) return '$result: $message';
    return result;
  }
}

class StorageDatabaseException extends StorageDatabaseError {
  const StorageDatabaseException([String? message]) : super(message);
}

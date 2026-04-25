abstract final class NetworkPolicy {
  /// How long to wait for a single network attempt before treating it as failed.
  static const Duration requestTimeout = Duration(seconds: 5);

  /// How many times to retry after the **first** failure.
  static const int maxRetryAttempts = 1;
}

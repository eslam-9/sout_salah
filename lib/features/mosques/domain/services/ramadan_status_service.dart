class RamadanStatusService {
  /// Computes the status color for a Ramadan day based on the recording count.
  /// 
  /// Business Rules:
  /// - 0 recordings: 'red'
  /// - 1-4 recordings: 'yellow'
  /// - 5 or more recordings: 'green'
  static String computeStatus(int recordingsCount) {
    if (recordingsCount == 0) return 'red';
    if (recordingsCount > 0 && recordingsCount < 5) return 'yellow';
    return 'green';
  }
}

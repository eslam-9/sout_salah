class RamadanMonthFactory {
  /// Generates a list of map entries representing the initial state
  /// of 30 days for a new Ramadan month.
  static List<Map<String, dynamic>> createDays({
    required String mosqueId,
    required int month,
    required int year,
  }) {
    final List<Map<String, dynamic>> daysToInsert = [];
    for (int i = 1; i <= 30; i++) {
      daysToInsert.add({
        'mosque_id': mosqueId,
        'day_number': i,
        'month': month,
        'year': year,
        'status': 'red', // Default status for a new day with 0 recordings
        'active': true,
      });
    }
    return daysToInsert;
  }
}

import 'package:equatable/equatable.dart';

class MonthYear extends Equatable {
  final int month;
  final int year;

  const MonthYear({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];

  String get arabicMonthName {
    const monthNames = [
      'مُحَرَّم',
      'صَفَر',
      'رَبِيع ٱلْأَوَّل',
      'رَبِيع ٱلْآخِر',
      'جُمَادَىٰ ٱلْأُولَىٰ',
      'جُمَادَىٰ ٱلْآخِرَة',
      'رَجَب',
      'شَعْبَان',
      'رَمَضَان',
      'شَوَّال',
      'ذُو ٱلْقَعْدَة',
      'ذُو ٱلْحِجَّة',
    ];
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return 'شهر $month';
  }
}

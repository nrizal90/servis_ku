extension DateTimeExt on DateTime {
  DateTime addYears(int years) =>
      DateTime(year + years, month, day);

  bool isSameDayOrBefore(DateTime other) =>
      !isAfter(DateTime(other.year, other.month, other.day + 1));
}

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

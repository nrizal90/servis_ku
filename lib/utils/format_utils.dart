import 'package:intl/intl.dart';

final _dateFormat = DateFormat('d MMM yyyy', 'id_ID');
final _numberFormat = NumberFormat('#,###', 'id_ID');

String formatDate(DateTime date) => _dateFormat.format(date);

String formatNumber(int number) =>
    _numberFormat.format(number).replaceAll(',', '.');

String formatCurrency(int amount) => 'Rp ${formatNumber(amount)}';

String formatKm(int km) => '${formatNumber(km)} km';

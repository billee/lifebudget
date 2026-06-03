import 'package:intl/intl.dart';

final _commaFormat = NumberFormat('#,##0', 'en_US');

String formatAmount(double amount) {
  return _commaFormat.format(amount.round());
}

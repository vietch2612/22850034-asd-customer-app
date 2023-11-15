// currency_formatter.dart

import 'package:intl/intl.dart';

Future<String> formatCurrency(int amount) async {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
  return currencyFormat.format(amount);
}

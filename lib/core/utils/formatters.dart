import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _date = DateFormat('dd/MM/yyyy');

  static String currency(num? value) => _currency.format(value ?? 0);

  static String dateTime(DateTime? value) {
    if (value == null) return '';
    return _dateTime.format(value.toLocal());
  }

  static String date(DateTime? value) {
    if (value == null) return '';
    return _date.format(value.toLocal());
  }
}

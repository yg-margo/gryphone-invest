import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compact();
  static final _percentFormatter = NumberFormat('+#,##0.00%;-#,##0.00%');
  static final _dateFormatter = DateFormat('MMM d, yyyy');
  static final _shortDateFormatter = DateFormat('MMM d');

  static String currency(double value) => _currencyFormatter.format(value);

  static String compactCurrency(double value) {
    if (value.abs() >= 1000000) {
      return '\$${_compactFormatter.format(value)}';
    }
    return _currencyFormatter.format(value);
  }

  static String percent(double value) => _percentFormatter.format(value / 100);

  static String percentRaw(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

  static String date(DateTime date) => _dateFormatter.format(date);

  static String shortDate(DateTime date) => _shortDateFormatter.format(date);

  static String number(double value, {int decimals = 2}) =>
      value.toStringAsFixed(decimals);

  static String change(double value) =>
      '${value >= 0 ? '+' : ''}\$${value.abs().toStringAsFixed(2)}';
}

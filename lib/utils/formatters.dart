import 'package:intl/intl.dart';

class Formatters {
  static final _money = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
  static final _moneyDecimal =
      NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  static final _date = DateFormat('dd MMM yyyy');
  static final _iso = DateFormat('yyyy-MM-dd');

  static String money(double value, {String currency = 'INR'}) {
    if (currency == 'QAR') {
      return NumberFormat.currency(symbol: 'QAR ', decimalDigits: 0)
          .format(value);
    }
    if (currency == 'USD') {
      return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);
    }
    return value % 1 == 0 ? _money.format(value) : _moneyDecimal.format(value);
  }

  static String dateDisplay(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return _date.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  static String todayIso() => _iso.format(DateTime.now());

  static String toIso(DateTime dt) => _iso.format(dt);

  static String timeOfDay(String time) {
    if (time.isEmpty) return '';
    try {
      // Parse HH:mm format and return it as is, or parse and reformat if needed
      // For simplicity, we'll return the time string if it's in expected format
      return time.length >= 5 ? time.substring(0, 5) : time;
    } catch (_) {
      return time;
    }
  }
}

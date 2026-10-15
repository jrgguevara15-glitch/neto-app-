import 'package:intl/intl.dart';

final _thousands = NumberFormat('#,##0', 'es_CL');

/// $12.345 / -$12.345
String clp(num value) {
  final v = value.round();
  return '${v < 0 ? '-' : ''}\$${_thousands.format(v.abs())}';
}

String kmText(double km) =>
    km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1);

/// 3 h 05 min
String durationText(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h h $m min' : '${d.inMinutes} min';
}

String timeText(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

const _weekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "jueves 15 de octubre"
String dayText(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} de ${_months[d.month - 1]}';

/// Lee "12.500", "12500" o "$12.500" como 12500. Devuelve null si está vacío.
int? parseClp(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : int.parse(digits);
}

/// Lee "12,5" o "12.5" como 12.5. Devuelve null si está vacío o no es número.
double? parseDecimal(String text) {
  final t = text.trim().replaceAll(',', '.');
  return t.isEmpty ? null : double.tryParse(t);
}

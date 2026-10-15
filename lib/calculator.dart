import 'models.dart';

/// Desglose de un día: de lo bruto a lo que realmente queda líquido.
class DaySummary {
  const DaySummary({
    required this.tripsGross,
    required this.extraIncome,
    required this.tripCount,
    required this.km,
    required this.fuel,
    required this.tag,
    required this.vehicleCost,
    required this.maintenance,
    required this.tax,
    required this.otherExpenses,
    required this.worked,
  });

  final int tripsGross;
  final int extraIncome;
  final int tripCount;
  final double km;
  final int fuel;
  final int tag;

  /// Depreciación (auto propio) o arriendo del día (auto arrendado).
  final int vehicleCost;
  final int maintenance;
  final int tax;
  final int otherExpenses;
  final Duration worked;

  int get gross => tripsGross + extraIncome;

  int get totalCosts =>
      fuel + tag + vehicleCost + maintenance + tax + otherExpenses;

  int get net => gross - totalCosts;

  /// Líquido por hora trabajada; null si no hay tiempo registrado.
  int? get netPerHour {
    final hours = worked.inSeconds / 3600;
    return hours < 1 / 60 ? null : (net / hours).round();
  }

  static const empty = DaySummary(
    tripsGross: 0,
    extraIncome: 0,
    tripCount: 0,
    km: 0,
    fuel: 0,
    tag: 0,
    vehicleCost: 0,
    maintenance: 0,
    tax: 0,
    otherExpenses: 0,
    worked: Duration.zero,
  );
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Día al que pertenece un registro: si ocurrió durante una jornada, el día en
/// que empezó esa jornada (una jornada nocturna que pasa la medianoche cuenta
/// entera en su día de inicio); si no, el día calendario.
DateTime workDayOf(DateTime at, List<Shift> shifts, DateTime now) {
  for (final s in shifts) {
    if (!at.isBefore(s.start) && !at.isAfter(s.end ?? now)) {
      return DateTime(s.start.year, s.start.month, s.start.day);
    }
  }
  return DateTime(at.year, at.month, at.day);
}

/// Calcula el resumen del día [day] (hora local).
///
/// Los km del día son el mayor entre la suma de km de los viajes y la suma de
/// km de las jornadas: así los km sin pasajero cuentan cuando se registran al
/// cerrar la jornada, y nunca se cuenta dos veces el mismo tramo.
DaySummary summarizeDay({
  required DateTime day,
  required Settings settings,
  required List<Trip> trips,
  required List<ExtraIncome> incomes,
  required List<Expense> expenses,
  required List<Shift> shifts,
  required DateTime now,
}) {
  bool inDay(DateTime at) => sameDay(workDayOf(at, shifts, now), day);
  final dayTrips = trips.where((t) => inDay(t.at)).toList();
  final dayIncomes = incomes.where((i) => inDay(i.at));
  final dayExpenses = expenses.where((e) => inDay(e.at));
  final dayShifts = shifts.where((s) => sameDay(s.start, day)).toList();

  final tripsGross = dayTrips.fold(0, (s, t) => s + t.amount);
  final extra = dayIncomes.fold(0, (s, i) => s + i.amount);
  final tripKm = dayTrips.fold(0.0, (s, t) => s + t.km);
  final shiftKm = dayShifts.fold(0.0, (s, sh) => s + (sh.km ?? 0));
  final km = tripKm > shiftKm ? tripKm : shiftKm;

  final tagFromTrips = dayTrips.fold(0, (s, t) => s + t.tag);
  var tagExpenses = 0;
  var otherExpenses = 0;
  for (final e in dayExpenses) {
    if (e.category == ExpenseCategory.tag) {
      tagExpenses += e.amount;
    } else {
      otherExpenses += e.amount;
    }
  }

  final hasActivity =
      dayTrips.isNotEmpty ||
      dayShifts.isNotEmpty ||
      dayIncomes.isNotEmpty ||
      dayExpenses.isNotEmpty;

  final vehicleCost = settings.ownership == VehicleOwnership.owned
      ? km * settings.depreciationPerKm
      : (hasActivity ? settings.rentPerDay : 0.0);

  final worked = dayShifts.fold(
    Duration.zero,
    (s, sh) => s + sh.durationAt(now),
  );

  return DaySummary(
    tripsGross: tripsGross,
    extraIncome: extra,
    tripCount: dayTrips.length,
    km: km,
    fuel: (km * settings.fuelCostPerKm).round(),
    tag: tagFromTrips + tagExpenses,
    vehicleCost: vehicleCost.round(),
    maintenance: (km * settings.maintenancePerKm).round(),
    tax: (tripsGross * settings.taxRetentionPercent / 100).round(),
    otherExpenses: otherExpenses,
    worked: worked,
  );
}

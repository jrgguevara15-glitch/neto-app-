import 'package:flutter_test/flutter_test.dart';
import 'package:neto/calculator.dart';
import 'package:neto/format.dart';
import 'package:neto/models.dart';

void main() {
  // Bencina $1.200/l a 12 km/l = $100/km. Depreciación (10M - 2M) / 200.000 = $40/km.
  const owned = Settings(
    ownership: VehicleOwnership.owned,
    kmPerLiter: 12,
    fuelPricePerLiter: 1200,
    carValue: 10000000,
    residualValue: 2000000,
    usefulLifeKm: 200000,
    maintenancePerKm: 20,
    taxRetentionPercent: 15,
  );
  final day = DateTime(2026, 10, 15);
  final now = DateTime(2026, 10, 15, 23);

  Trip trip(int h, int amount, {double km = 0, int tag = 0}) => Trip(
    id: 't$h$amount',
    at: DateTime(2026, 10, 15, h),
    platform: Platform.uber,
    amount: amount,
    km: km,
    tag: tag,
  );

  DaySummary run(
    Settings settings, {
    List<Trip> trips = const [],
    List<ExtraIncome> incomes = const [],
    List<Expense> expenses = const [],
    List<Shift> shifts = const [],
  }) => summarizeDay(
    day: day,
    settings: settings,
    trips: trips,
    incomes: incomes,
    expenses: expenses,
    shifts: shifts,
    now: now,
  );

  test('auto propio: descuenta bencina, TAG, depreciación, mantención, impuesto y gastos', () {
    final s = run(
      owned,
      trips: [trip(9, 10000, km: 10, tag: 500), trip(10, 20000, km: 20)],
      incomes: [
        ExtraIncome(id: 'i', at: DateTime(2026, 10, 15, 11), amount: 2000),
      ],
      expenses: [
        Expense(
          id: 'e1',
          at: DateTime(2026, 10, 15, 12),
          category: ExpenseCategory.food,
          amount: 3000,
        ),
        Expense(
          id: 'e2',
          at: DateTime(2026, 10, 15, 12),
          category: ExpenseCategory.tag,
          amount: 700,
        ),
      ],
    );
    expect(s.tripsGross, 30000);
    expect(s.gross, 32000);
    expect(s.km, 30);
    expect(s.fuel, 3000);
    expect(s.vehicleCost, 1200);
    expect(s.maintenance, 600);
    expect(s.tag, 1200);
    expect(s.tax, 4500); // 15% sólo sobre lo pagado por las apps
    expect(s.otherExpenses, 3000);
    expect(s.net, 32000 - 3000 - 1200 - 600 - 1200 - 4500 - 3000);
  });

  test(
    'auto arrendado: arriendo semanal prorrateado por día, sin depreciación',
    () {
      final rented = owned.copyWith(
        ownership: VehicleOwnership.rented,
        rentAmount: 140000,
        rentPeriod: RentPeriod.weekly,
      );
      final s = run(rented, trips: [trip(9, 10000, km: 10)]);
      expect(s.vehicleCost, 20000);
      expect(s.net, 10000 - 1000 - 20000 - 200 - 1500);
    },
  );

  test('día sin actividad no cobra arriendo', () {
    final rented = owned.copyWith(ownership: VehicleOwnership.rented);
    expect(run(rented).vehicleCost, 0);
    expect(run(rented).net, 0);
  });

  test('km de la jornada cuentan los km sin pasajero', () {
    final s = run(
      owned,
      trips: [trip(9, 10000, km: 10)],
      shifts: [
        Shift(
          id: 's',
          start: DateTime(2026, 10, 15, 8),
          end: DateTime(2026, 10, 15, 12),
          km: 25,
        ),
      ],
    );
    expect(s.km, 25);
    expect(s.fuel, 2500);
    expect(s.worked, const Duration(hours: 4));
    expect(s.netPerHour, (s.net / 4).round());
  });

  test('jornada nocturna: un viaje después de medianoche cuenta en el día que empezó', () {
    final shift = Shift(
      id: 's',
      start: DateTime(2026, 10, 15, 22),
      end: DateTime(2026, 10, 16, 3),
    );
    final late = Trip(
      id: 'late',
      at: DateTime(2026, 10, 16, 1),
      platform: Platform.didi,
      amount: 8000,
    );
    final s = summarizeDay(
      day: day,
      settings: owned,
      trips: [late],
      incomes: const [],
      expenses: const [],
      shifts: [shift],
      now: DateTime(2026, 10, 16, 4),
    );
    expect(s.tripsGross, 8000);
    expect(s.worked, const Duration(hours: 5));
    final nextDay = summarizeDay(
      day: DateTime(2026, 10, 16),
      settings: owned,
      trips: [late],
      incomes: const [],
      expenses: const [],
      shifts: [shift],
      now: DateTime(2026, 10, 16, 4),
    );
    expect(nextDay.tripsGross, 0);
  });

  test('formato y lectura de montos', () {
    expect(clp(12345), r'$12.345');
    expect(clp(-500), r'-$500');
    expect(parseClp(r'$12.500'), 12500);
    expect(parseClp(''), isNull);
    expect(parseDecimal('12,5'), 12.5);
  });

  test('configuración se guarda y se lee igual', () {
    final back = Settings.fromJson(owned.toJson());
    expect(back.toJson(), owned.toJson());
  });
}

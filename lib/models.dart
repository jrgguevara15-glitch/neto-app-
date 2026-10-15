/// Modelos de Neto. Todos los montos son pesos chilenos enteros (CLP).
library;

enum Platform { uber, didi, cabify }

extension PlatformLabel on Platform {
  String get label => switch (this) {
    Platform.uber => 'Uber',
    Platform.didi => 'DiDi',
    Platform.cabify => 'Cabify',
  };
}

enum VehicleOwnership { owned, rented }

enum RentPeriod { daily, weekly, monthly }

extension RentPeriodLabel on RentPeriod {
  String get label => switch (this) {
    RentPeriod.daily => 'Diario',
    RentPeriod.weekly => 'Semanal',
    RentPeriod.monthly => 'Mensual',
  };

  int get days => switch (this) {
    RentPeriod.daily => 1,
    RentPeriod.weekly => 7,
    RentPeriod.monthly => 30,
  };
}

enum ExpenseCategory { food, wash, parking, tag, maintenance, other }

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label => switch (this) {
    ExpenseCategory.food => 'Comida',
    ExpenseCategory.wash => 'Lavado',
    ExpenseCategory.parking => 'Estacionamiento',
    ExpenseCategory.tag => 'TAG / peaje',
    ExpenseCategory.maintenance => 'Mantención / reparación',
    ExpenseCategory.other => 'Otro',
  };
}

/// Configuración única del conductor y su auto.
class Settings {
  const Settings({
    this.ownership = VehicleOwnership.owned,
    this.kmPerLiter = 12,
    this.fuelPricePerLiter = 1300,
    this.carValue = 10000000,
    this.residualValue = 3000000,
    this.usefulLifeKm = 200000,
    this.maintenancePerKm = 25,
    this.rentAmount = 150000,
    this.rentPeriod = RentPeriod.weekly,
    this.taxRetentionPercent = 15.25,
  });

  final VehicleOwnership ownership;
  final double kmPerLiter;
  final int fuelPricePerLiter;

  // Auto propio
  final int carValue;
  final int residualValue;
  final int usefulLifeKm;

  /// Mantención, neumáticos, aceite, etc. Aplica a propio y arrendado.
  final int maintenancePerKm;

  // Auto arrendado
  final int rentAmount;
  final RentPeriod rentPeriod;

  /// Retención de impuesto sobre lo que pagan las plataformas.
  final double taxRetentionPercent;

  double get fuelCostPerKm =>
      kmPerLiter <= 0 ? 0 : fuelPricePerLiter / kmPerLiter;

  double get depreciationPerKm =>
      ownership == VehicleOwnership.owned &&
          usefulLifeKm > 0 &&
          carValue > residualValue
      ? (carValue - residualValue) / usefulLifeKm
      : 0;

  double get rentPerDay =>
      ownership == VehicleOwnership.rented ? rentAmount / rentPeriod.days : 0;

  Settings copyWith({
    VehicleOwnership? ownership,
    double? kmPerLiter,
    int? fuelPricePerLiter,
    int? carValue,
    int? residualValue,
    int? usefulLifeKm,
    int? maintenancePerKm,
    int? rentAmount,
    RentPeriod? rentPeriod,
    double? taxRetentionPercent,
  }) => Settings(
    ownership: ownership ?? this.ownership,
    kmPerLiter: kmPerLiter ?? this.kmPerLiter,
    fuelPricePerLiter: fuelPricePerLiter ?? this.fuelPricePerLiter,
    carValue: carValue ?? this.carValue,
    residualValue: residualValue ?? this.residualValue,
    usefulLifeKm: usefulLifeKm ?? this.usefulLifeKm,
    maintenancePerKm: maintenancePerKm ?? this.maintenancePerKm,
    rentAmount: rentAmount ?? this.rentAmount,
    rentPeriod: rentPeriod ?? this.rentPeriod,
    taxRetentionPercent: taxRetentionPercent ?? this.taxRetentionPercent,
  );

  Map<String, Object> toJson() => {
    'ownership': ownership.name,
    'kmPerLiter': kmPerLiter,
    'fuelPricePerLiter': fuelPricePerLiter,
    'carValue': carValue,
    'residualValue': residualValue,
    'usefulLifeKm': usefulLifeKm,
    'maintenancePerKm': maintenancePerKm,
    'rentAmount': rentAmount,
    'rentPeriod': rentPeriod.name,
    'taxRetentionPercent': taxRetentionPercent,
  };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
    ownership: VehicleOwnership.values.byName(j['ownership'] as String),
    kmPerLiter: (j['kmPerLiter'] as num).toDouble(),
    fuelPricePerLiter: j['fuelPricePerLiter'] as int,
    carValue: j['carValue'] as int,
    residualValue: j['residualValue'] as int,
    usefulLifeKm: j['usefulLifeKm'] as int,
    maintenancePerKm: j['maintenancePerKm'] as int,
    rentAmount: j['rentAmount'] as int,
    rentPeriod: RentPeriod.values.byName(j['rentPeriod'] as String),
    taxRetentionPercent: (j['taxRetentionPercent'] as num).toDouble(),
  );
}

/// Un viaje: lo que pagó la plataforma (ya sin su comisión).
class Trip {
  const Trip({
    required this.id,
    required this.at,
    required this.platform,
    required this.amount,
    this.km = 0,
    this.tag = 0,
  });

  final String id;
  final DateTime at;
  final Platform platform;
  final int amount;
  final double km;
  final int tag;

  Map<String, Object> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'platform': platform.name,
    'amount': amount,
    'km': km,
    'tag': tag,
  };

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
    id: j['id'] as String,
    at: DateTime.parse(j['at'] as String),
    platform: Platform.values.byName(j['platform'] as String),
    amount: j['amount'] as int,
    km: (j['km'] as num).toDouble(),
    tag: j['tag'] as int,
  );
}

/// Ingreso fuera de las plataformas (propina en efectivo, viaje particular...).
class ExtraIncome {
  const ExtraIncome({
    required this.id,
    required this.at,
    required this.amount,
    this.note = '',
  });

  final String id;
  final DateTime at;
  final int amount;
  final String note;

  Map<String, Object> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'amount': amount,
    'note': note,
  };

  factory ExtraIncome.fromJson(Map<String, dynamic> j) => ExtraIncome(
    id: j['id'] as String,
    at: DateTime.parse(j['at'] as String),
    amount: j['amount'] as int,
    note: j['note'] as String,
  );
}

class Expense {
  const Expense({
    required this.id,
    required this.at,
    required this.category,
    required this.amount,
    this.note = '',
  });

  final String id;
  final DateTime at;
  final ExpenseCategory category;
  final int amount;
  final String note;

  Map<String, Object> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'category': category.name,
    'amount': amount,
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    at: DateTime.parse(j['at'] as String),
    category: ExpenseCategory.values.byName(j['category'] as String),
    amount: j['amount'] as int,
    note: j['note'] as String,
  );
}

/// Una jornada de trabajo. [end] es null mientras está en curso.
/// [km] son los km totales recorridos (incluye km sin pasajero); es opcional.
class Shift {
  const Shift({required this.id, required this.start, this.end, this.km});

  final String id;
  final DateTime start;
  final DateTime? end;
  final double? km;

  bool get isOpen => end == null;

  Duration durationAt(DateTime now) => (end ?? now).difference(start);

  Shift close(DateTime at, double? km) =>
      Shift(id: id, start: start, end: at, km: km);

  Map<String, Object?> toJson() => {
    'id': id,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'km': km,
  };

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
    id: j['id'] as String,
    start: DateTime.parse(j['start'] as String),
    end: j['end'] == null ? null : DateTime.parse(j['end'] as String),
    km: (j['km'] as num?)?.toDouble(),
  );
}

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calculator.dart';
import 'format.dart';
import 'models.dart';

/// Estado de la app, guardado en el propio teléfono.
class NetoStore extends ChangeNotifier {
  NetoStore(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  final _random = Random();

  Settings settings = const Settings();
  bool configured = false;
  List<Trip> trips = [];
  List<ExtraIncome> incomes = [];
  List<Expense> expenses = [];
  List<Shift> shifts = [];

  Shift? get openShift {
    for (final s in shifts) {
      if (s.isOpen) return s;
    }
    return null;
  }

  /// Día de trabajo actual: el de la jornada abierta, o hoy.
  DateTime get currentWorkDay {
    final d = openShift?.start ?? DateTime.now();
    return _dateOnly(d);
  }

  DaySummary summaryFor(DateTime day, {DateTime? now}) => summarizeDay(
    day: day,
    settings: settings,
    trips: trips,
    incomes: incomes,
    expenses: expenses,
    shifts: shifts,
    now: now ?? DateTime.now(),
  );

  /// Días con algún registro, del más reciente al más antiguo.
  List<DateTime> activeDays() {
    final now = DateTime.now();
    DateTime dayOf(DateTime at) => workDayOf(at, shifts, now);
    final days = <DateTime>{
      for (final t in trips) dayOf(t.at),
      for (final i in incomes) dayOf(i.at),
      for (final e in expenses) dayOf(e.at),
      for (final s in shifts) _dateOnly(s.start),
    }.toList()..sort((a, b) => b.compareTo(a));
    return days;
  }

  /// Registros (viajes, ingresos y gastos) de un día, del más nuevo al más viejo.
  List<EntryView> entriesFor(DateTime day) {
    final now = DateTime.now();
    bool inDay(DateTime at) => sameDay(workDayOf(at, shifts, now), day);
    final list = <EntryView>[
      for (final t in trips.where((t) => inDay(t.at)))
        EntryView(
          id: t.id,
          at: t.at,
          title: 'Viaje ${t.platform.label}',
          detail: [
            if (t.km > 0) '${kmText(t.km)} km',
            if (t.tag > 0) 'TAG ${clp(t.tag)}',
          ].join(' · '),
          amount: t.amount,
        ),
      for (final i in incomes.where((i) => inDay(i.at)))
        EntryView(
          id: i.id,
          at: i.at,
          title: 'Otro ingreso',
          detail: i.note,
          amount: i.amount,
        ),
      for (final e in expenses.where((e) => inDay(e.at)))
        EntryView(
          id: e.id,
          at: e.at,
          title: e.category.label,
          detail: e.note,
          amount: -e.amount,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  Future<void> saveSettings(Settings value) async {
    settings = value;
    configured = true;
    notifyListeners();
    await _prefs.setString('settings', jsonEncode(value.toJson()));
    await _prefs.setBool('configured', true);
  }

  Future<void> startShift() async {
    if (openShift != null) return;
    shifts = [...shifts, Shift(id: _id(), start: DateTime.now())];
    await _saveShifts();
  }

  Future<void> endShift({double? km}) async {
    final open = openShift;
    if (open == null) return;
    shifts = [
      for (final s in shifts) s.id == open.id ? s.close(DateTime.now(), km) : s,
    ];
    await _saveShifts();
  }

  Future<void> addTrip({
    required Platform platform,
    required int amount,
    double km = 0,
    int tag = 0,
  }) async {
    trips = [
      ...trips,
      Trip(
        id: _id(),
        at: DateTime.now(),
        platform: platform,
        amount: amount,
        km: km,
        tag: tag,
      ),
    ];
    notifyListeners();
    await _saveList('trips', trips.map((t) => t.toJson()));
  }

  Future<void> addIncome({required int amount, String note = ''}) async {
    incomes = [
      ...incomes,
      ExtraIncome(id: _id(), at: DateTime.now(), amount: amount, note: note),
    ];
    notifyListeners();
    await _saveList('incomes', incomes.map((i) => i.toJson()));
  }

  Future<void> addExpense({
    required ExpenseCategory category,
    required int amount,
    String note = '',
  }) async {
    expenses = [
      ...expenses,
      Expense(
        id: _id(),
        at: DateTime.now(),
        category: category,
        amount: amount,
        note: note,
      ),
    ];
    notifyListeners();
    await _saveList('expenses', expenses.map((e) => e.toJson()));
  }

  Future<void> deleteEntry(String id) async {
    trips = trips.where((t) => t.id != id).toList();
    incomes = incomes.where((i) => i.id != id).toList();
    expenses = expenses.where((e) => e.id != id).toList();
    notifyListeners();
    await _saveList('trips', trips.map((t) => t.toJson()));
    await _saveList('incomes', incomes.map((i) => i.toJson()));
    await _saveList('expenses', expenses.map((e) => e.toJson()));
  }

  void _load() {
    final s = _prefs.getString('settings');
    if (s != null) {
      settings = Settings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    }
    configured = _prefs.getBool('configured') ?? false;
    trips = _readList('trips', Trip.fromJson);
    incomes = _readList('incomes', ExtraIncome.fromJson);
    expenses = _readList('expenses', Expense.fromJson);
    shifts = _readList('shifts', Shift.fromJson);
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) parse) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => parse(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveShifts() async {
    notifyListeners();
    await _saveList('shifts', shifts.map((s) => s.toJson()));
  }

  Future<void> _saveList(String key, Iterable<Object> items) =>
      _prefs.setString(key, jsonEncode(items.toList()));

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Fila para mostrar un registro en una lista.
class EntryView {
  const EntryView({
    required this.id,
    required this.at,
    required this.title,
    required this.detail,
    required this.amount,
  });

  final String id;
  final DateTime at;
  final String title;
  final String detail;

  /// Positivo para ingresos, negativo para gastos.
  final int amount;
}

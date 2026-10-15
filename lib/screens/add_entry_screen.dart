import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';

enum _Kind { trip, income, expense }

/// Agregar un viaje, otro ingreso o un gasto. Pensado para hacerlo en segundos:
/// la plataforma elegida se recuerda y el monto queda enfocado al abrir.
class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key, required this.store});

  final NetoStore store;

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  static Platform _lastPlatform = Platform.uber;

  _Kind _kind = _Kind.trip;
  Platform _platform = _lastPlatform;
  ExpenseCategory _category = ExpenseCategory.food;
  final _amount = TextEditingController();
  final _km = TextEditingController();
  final _tag = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_amount, _km, _tag, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseClp(_amount.text);
    if (amount == null || amount == 0) {
      setState(() => _error = 'Ingresa el monto');
      return;
    }
    final store = widget.store;
    switch (_kind) {
      case _Kind.trip:
        _lastPlatform = _platform;
        await store.addTrip(
          platform: _platform,
          amount: amount,
          km: parseDecimal(_km.text) ?? 0,
          tag: parseClp(_tag.text) ?? 0,
        );
      case _Kind.income:
        await store.addIncome(amount: amount, note: _note.text.trim());
      case _Kind.expense:
        await store.addExpense(
          category: _category,
          amount: amount,
          note: _note.text.trim(),
        );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Kind>(
            segments: const [
              ButtonSegment(
                value: _Kind.trip,
                label: Text('Viaje'),
                icon: Icon(Icons.local_taxi),
              ),
              ButtonSegment(
                value: _Kind.income,
                label: Text('Ingreso'),
                icon: Icon(Icons.add_card),
              ),
              ButtonSegment(
                value: _Kind.expense,
                label: Text('Gasto'),
                icon: Icon(Icons.receipt_long),
              ),
            ],
            selected: {_kind},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 20),
          if (_kind == _Kind.trip)
            Wrap(
              spacing: 8,
              children: [
                for (final p in Platform.values)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: _platform == p,
                    onSelected: (_) => setState(() => _platform = p),
                  ),
              ],
            ),
          if (_kind == _Kind.expense)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in ExpenseCategory.values)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: theme.textTheme.headlineMedium,
            decoration: InputDecoration(
              labelText: switch (_kind) {
                _Kind.trip => 'Lo que te pagó ${_platform.label}',
                _Kind.income => 'Monto del ingreso',
                _Kind.expense => 'Monto del gasto',
              },
              prefixText: r'$ ',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          if (_kind == _Kind.trip) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _km,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Km (opcional)',
                      suffixText: 'km',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tag,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'TAG (opcional)',
                      prefixText: r'$ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa lo que te paga la app por el viaje, ya sin su comisión. '
              'La bencina, el desgaste y el impuesto se descuentan solos.',
              style: theme.textTheme.bodySmall,
            ),
          ] else
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
          if (_kind == _Kind.expense) ...[
            const SizedBox(height: 8),
            Text(
              'La bencina no se anota aquí: se calcula por los km recorridos.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Guardar', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

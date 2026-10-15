import 'package:flutter/material.dart';

import '../calculator.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';

/// Desglose bruto → líquido de un día.
class BreakdownCard extends StatelessWidget {
  const BreakdownCard({
    super.key,
    required this.summary,
    required this.settings,
  });

  final DaySummary summary;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final owned = settings.ownership == VehicleOwnership.owned;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row('Viajes (${s.tripCount})', s.tripsGross),
            if (s.extraIncome > 0) _Row('Otros ingresos', s.extraIncome),
            _Row('Bruto', s.gross, bold: true),
            const Divider(),
            _Row('Bencina (${kmText(s.km)} km)', -s.fuel),
            _Row('TAG / peajes', -s.tag),
            _Row(
              owned ? 'Depreciación del auto' : 'Arriendo del auto',
              -s.vehicleCost,
            ),
            _Row('Mantención', -s.maintenance),
            _Row('Impuesto (${_pct(settings.taxRetentionPercent)}%)', -s.tax),
            _Row('Otros gastos', -s.otherExpenses),
            const Divider(),
            _Row('Líquido', s.net, bold: true, highlight: true),
          ],
        ),
      ),
    );
  }

  static String _pct(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toString().replaceAll('.', ',');
}

class _Row extends StatelessWidget {
  const _Row(
    this.label,
    this.amount, {
    this.bold = false,
    this.highlight = false,
  });

  final String label;
  final int amount;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var style = theme.textTheme.bodyLarge!;
    if (bold) style = style.copyWith(fontWeight: FontWeight.bold);
    if (highlight) {
      style = theme.textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.bold,
        color: amount < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(clp(amount), style: style),
        ],
      ),
    );
  }
}

/// Lista de registros de un día; deslizar a la izquierda para borrar.
class EntryList extends StatelessWidget {
  const EntryList({super.key, required this.store, required this.entries});

  final NetoStore store;
  final List<EntryView> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Sin registros todavía. Toca + para agregar un viaje.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final e in entries)
          Dismissible(
            key: ValueKey(e.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: theme.colorScheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline),
            ),
            confirmDismiss: (_) => showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('¿Borrar este registro?'),
                content: Text('${e.title} · ${clp(e.amount)}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Borrar'),
                  ),
                ],
              ),
            ),
            onDismissed: (_) => store.deleteEntry(e.id),
            child: ListTile(
              leading: Text(timeText(e.at)),
              title: Text(e.title),
              subtitle: e.detail.isEmpty ? null : Text(e.detail),
              trailing: Text(
                clp(e.amount),
                style: theme.textTheme.titleMedium!.copyWith(
                  color: e.amount < 0 ? theme.colorScheme.error : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

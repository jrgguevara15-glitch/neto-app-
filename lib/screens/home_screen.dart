import 'dart:async';

import 'package:flutter/material.dart';

import '../format.dart';
import '../store.dart';
import 'add_entry_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final NetoStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;

  NetoStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    // Refresca el tiempo trabajado y el arriendo mientras la jornada corre.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _toggleShift() async {
    if (store.openShift == null) {
      await store.startShift();
      return;
    }
    final km = await showDialog<_EndShiftResult>(
      context: context,
      builder: (_) => const _EndShiftDialog(),
    );
    if (km != null) await store.endShift(km: km.km);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = store.currentWorkDay;
    final summary = store.summaryFor(day);
    final open = store.openShift;
    final perHour = summary.netPerHour;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neto'),
        actions: [
          IconButton(
            tooltip: 'Días anteriores',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryScreen(store: store)),
            ),
          ),
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen(store: store)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        tooltip: 'Agregar',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEntryScreen(store: store)),
        ),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(
            dayText(day),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Líquido hoy',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            clp(summary.net),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: summary.net < 0
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              durationText(summary.worked),
              if (perHour != null) '${clp(perHour)} / hora',
            ].join('  ·  '),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: open == null
                ? FilledButton.icon(
                    onPressed: _toggleShift,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Empezar jornada',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : FilledButton.tonalIcon(
                    onPressed: _toggleShift,
                    icon: const Icon(Icons.stop),
                    label: Text(
                      'Terminar jornada (desde ${timeText(open.start)})',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          BreakdownCard(summary: summary, settings: store.settings),
          const SizedBox(height: 8),
          EntryList(store: store, entries: store.entriesFor(day)),
        ],
      ),
    );
  }
}

class _EndShiftResult {
  const _EndShiftResult(this.km);
  final double? km;
}

/// Al terminar, pide (opcional) los km totales de la jornada, incluidos los km
/// sin pasajero, para que la bencina y el desgaste salgan completos.
class _EndShiftDialog extends StatefulWidget {
  const _EndShiftDialog();

  @override
  State<_EndShiftDialog> createState() => _EndShiftDialogState();
}

class _EndShiftDialogState extends State<_EndShiftDialog> {
  final _km = TextEditingController();

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Terminar jornada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¿Cuántos km hiciste en total? Incluye los km sin pasajero '
            '(mira el cuentakilómetros). Si lo dejas vacío se usan los km de los viajes.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _km,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Km de la jornada',
              suffixText: 'km',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _EndShiftResult(parseDecimal(_km.text))),
          child: const Text('Terminar'),
        ),
      ],
    );
  }
}

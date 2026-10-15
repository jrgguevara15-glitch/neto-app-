import 'package:flutter/material.dart';

import '../format.dart';
import '../store.dart';
import 'widgets.dart';

/// Días anteriores con su líquido.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.store});

  final NetoStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Días anteriores')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final days = store.activeDays();
          if (days.isEmpty) {
            return const Center(
              child: Text('Todavía no hay días registrados.'),
            );
          }
          final theme = Theme.of(context);
          return ListView(
            children: [
              for (final day in days)
                Builder(
                  builder: (context) {
                    final s = store.summaryFor(day);
                    return ListTile(
                      title: Text(dayText(day)),
                      subtitle: Text(
                        '${s.tripCount} viajes · ${durationText(s.worked)} · bruto ${clp(s.gross)}',
                      ),
                      trailing: Text(
                        clp(s.net),
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: s.net < 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DayDetailScreen(store: store, day: day),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.store, required this.day});

  final NetoStore store;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(dayText(day))),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final s = store.summaryFor(day);
          final perHour = s.netPerHour;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                [
                  'Trabajaste ${durationText(s.worked)}',
                  if (perHour != null) '${clp(perHour)} líquido por hora',
                ].join(' · '),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              BreakdownCard(summary: s, settings: store.settings),
              EntryList(store: store, entries: store.entriesFor(day)),
            ],
          );
        },
      ),
    );
  }
}

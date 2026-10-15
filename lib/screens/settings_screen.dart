import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';

/// Configuración del auto y de los costos. Se llena una vez al inicio.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store, this.firstRun = false});

  final NetoStore store;
  final bool firstRun;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late VehicleOwnership _ownership;
  late RentPeriod _rentPeriod;
  late final TextEditingController _kmPerLiter;
  late final TextEditingController _fuelPrice;
  late final TextEditingController _carValue;
  late final TextEditingController _residual;
  late final TextEditingController _lifeKm;
  late final TextEditingController _maintenance;
  late final TextEditingController _rent;
  late final TextEditingController _tax;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.store.settings;
    _ownership = s.ownership;
    _rentPeriod = s.rentPeriod;
    String dec(double v) => v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toString().replaceAll('.', ',');
    _kmPerLiter = TextEditingController(text: dec(s.kmPerLiter));
    _fuelPrice = TextEditingController(text: '${s.fuelPricePerLiter}');
    _carValue = TextEditingController(text: '${s.carValue}');
    _residual = TextEditingController(text: '${s.residualValue}');
    _lifeKm = TextEditingController(text: '${s.usefulLifeKm}');
    _maintenance = TextEditingController(text: '${s.maintenancePerKm}');
    _rent = TextEditingController(text: '${s.rentAmount}');
    _tax = TextEditingController(text: dec(s.taxRetentionPercent));
  }

  @override
  void dispose() {
    for (final c in [
      _kmPerLiter,
      _fuelPrice,
      _carValue,
      _residual,
      _lifeKm,
      _maintenance,
      _rent,
      _tax,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final kmPerLiter = parseDecimal(_kmPerLiter.text);
    final fuel = parseClp(_fuelPrice.text);
    final tax = parseDecimal(_tax.text);
    final maintenance = parseClp(_maintenance.text) ?? 0;
    if (kmPerLiter == null || kmPerLiter <= 0 || fuel == null || fuel <= 0) {
      setState(
        () => _error = 'Revisa el rendimiento y el precio de la bencina.',
      );
      return;
    }
    if (tax == null || tax < 0 || tax > 100) {
      setState(
        () => _error = 'El impuesto debe ser un porcentaje entre 0 y 100.',
      );
      return;
    }
    var next = widget.store.settings.copyWith(
      ownership: _ownership,
      kmPerLiter: kmPerLiter,
      fuelPricePerLiter: fuel,
      maintenancePerKm: maintenance,
      taxRetentionPercent: tax,
      rentPeriod: _rentPeriod,
    );
    if (_ownership == VehicleOwnership.owned) {
      final value = parseClp(_carValue.text);
      final residual = parseClp(_residual.text) ?? 0;
      final life = parseClp(_lifeKm.text);
      if (value == null || life == null || life <= 0 || residual > value) {
        setState(
          () => _error = 'Revisa el valor del auto, el valor de reventa y los km de vida útil.',
        );
        return;
      }
      next = next.copyWith(
        carValue: value,
        residualValue: residual,
        usefulLifeKm: life,
      );
    } else {
      final rent = parseClp(_rent.text);
      if (rent == null || rent <= 0) {
        setState(() => _error = 'Ingresa cuánto pagas de arriendo.');
        return;
      }
      next = next.copyWith(rentAmount: rent);
    }
    await widget.store.saveSettings(next);
    if (mounted && !widget.firstRun) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget field(
      TextEditingController c,
      String label, {
      String? prefix,
      String? suffix,
      String? help,
      bool decimal = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          suffixText: suffix,
          helperText: help,
          helperMaxLines: 3,
        ),
      ),
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(title, style: theme.textTheme.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firstRun ? 'Bienvenido a Neto' : 'Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.firstRun)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Cuéntanos de tu auto una sola vez. Con esto Neto descuenta '
                'de cada viaje la bencina, el desgaste y el impuesto, y te muestra '
                'lo que realmente te queda. Puedes cambiarlo cuando quieras.',
              ),
            ),
          section('Tu auto'),
          SegmentedButton<VehicleOwnership>(
            segments: const [
              ButtonSegment(
                value: VehicleOwnership.owned,
                label: Text('Propio'),
              ),
              ButtonSegment(
                value: VehicleOwnership.rented,
                label: Text('Arrendado'),
              ),
            ],
            selected: {_ownership},
            onSelectionChanged: (s) => setState(() => _ownership = s.first),
          ),
          const SizedBox(height: 16),
          if (_ownership == VehicleOwnership.owned) ...[
            field(_carValue, 'Valor actual del auto', prefix: r'$ '),
            field(
              _residual,
              'Valor en que lo venderías al final',
              prefix: r'$ ',
            ),
            field(
              _lifeKm,
              'Km que le quedan de uso',
              suffix: 'km',
              help: 'La diferencia de valor dividida por estos km es la depreciación por km.',
            ),
          ] else ...[
            SegmentedButton<RentPeriod>(
              segments: [
                for (final p in RentPeriod.values)
                  ButtonSegment(value: p, label: Text(p.label)),
              ],
              selected: {_rentPeriod},
              onSelectionChanged: (s) => setState(() => _rentPeriod = s.first),
            ),
            const SizedBox(height: 12),
            field(
              _rent,
              'Arriendo ${_rentPeriod.label.toLowerCase()}',
              prefix: r'$ ',
              help: 'Se descuenta la parte de un día en cada día que trabajes.',
            ),
          ],
          field(
            _maintenance,
            'Mantención por km',
            prefix: r'$ ',
            suffix: '/km',
            help: 'Aceite, neumáticos, frenos, revisiones. Si no sabes, \$25 por km es una referencia.',
          ),
          section('Bencina'),
          field(_kmPerLiter, 'Rendimiento', suffix: 'km/l', decimal: true),
          field(_fuelPrice, 'Precio del litro', prefix: r'$ '),
          section('Impuesto'),
          field(
            _tax,
            'Retención sobre lo que pagan las apps',
            suffix: '%',
            decimal: true,
            help: 'Retención de boleta de honorarios. Si la app ya te paga con el impuesto descontado, pon 0.',
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _save,
              child: Text(
                widget.firstRun ? 'Empezar' : 'Guardar',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

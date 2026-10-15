import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neto/main.dart';
import 'package:neto/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('configurar, empezar jornada, agregar viaje y ver el líquido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = NetoStore(prefs);
    await tester.pumpWidget(NetoApp(store: store));

    // Primera vez: configuración con valores por defecto.
    expect(find.text('Bienvenido a Neto'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Empezar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(find.text('Líquido hoy'), findsOneWidget);
    await tester.tap(find.text('Empezar jornada'));
    await tester.pumpAndSettle();
    expect(store.openShift, isNotNull);

    await tester.tap(find.byTooltip('Agregar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DiDi'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '10000');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(store.trips, hasLength(1));
    expect(find.text('Viaje DiDi'), findsOneWidget);
    // Sin km: sólo se descuenta el impuesto por defecto (15,25%).
    expect(find.text(r'$8.475'), findsWidgets);

    // Persistencia: un store nuevo lee lo mismo.
    final reloaded = NetoStore(prefs);
    expect(reloaded.configured, isTrue);
    expect(reloaded.trips.single.amount, 10000);
  });
}

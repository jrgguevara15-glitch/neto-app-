# Neto

Cuánto te queda **realmente líquido** manejando con Uber, DiDi y Cabify.

App para celular (iPhone y Android) hecha en Flutter. Los datos se guardan
solo en el teléfono.

## Qué hace (Fase 1)

- Configuración única del auto: propio (depreciación por km) o arrendado
  (arriendo diario, semanal o mensual prorrateado por día trabajado),
  rendimiento, precio de la bencina, mantención por km y % de retención.
- Botón para empezar y terminar la jornada (mide el tiempo trabajado y, al
  terminar, pide los km totales para contar los km sin pasajero).
- Registrar viajes (plataforma, monto, km y TAG opcionales), otros ingresos
  y gastos.
- Líquido del día: bruto − bencina − TAG − depreciación/arriendo −
  mantención − impuesto − otros gastos, y líquido por hora.
- Historial de días con su detalle.

## Desarrollo

```
flutter pub get
flutter analyze
flutter test
flutter run
```

Ver `AGENTS.md`, `STATUS.md` y `BACKLOG.md`.

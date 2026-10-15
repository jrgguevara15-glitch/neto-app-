# ESTADO DE NETO

## Fase 1 — Versión manual — EN VALIDACIÓN

Implementado:

- Configuración inicial y editable: auto propio o arrendado, bencina,
  mantención, % de retención.
- Jornada: empezar/terminar, tiempo trabajado, km totales opcionales al
  terminar. Una jornada que pasa la medianoche cuenta entera en su día de
  inicio.
- Registro de viajes (Uber/DiDi/Cabify, monto, km y TAG opcionales), otros
  ingresos y gastos por categoría. Borrar deslizando a la izquierda.
- Resumen del día (bruto → líquido, líquido por hora) e historial de días.
- Pruebas: 8/8 (cálculo, formato, persistencia y flujo completo de la app).
- `flutter analyze`: sin issues.

Pendiente: prueba funcional del usuario en su iPhone.

## Fases siguientes (no abiertas)

- Fase 2 — GPS: km automáticos y TAG por pórtico.
- Fase 3 — Datos de las apps: pantallazo con lectura de texto, importación
  de resúmenes semanales y cuadre.
- Fase 4 — Metas semanal/mensual/anual y proyección de flujo de caja.

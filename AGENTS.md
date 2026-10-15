# REGLAS DE DESARROLLO DE NETO

Mismas reglas de trabajo que Zentra.

## Regla principal

Neto se desarrolla por fases y bloques cerrados. No comenzar otra
funcionalidad mientras exista un bloque activo.

## Flujo obligatorio

Implementar -> flutter analyze (0 issues) -> flutter test -> prueba funcional
del usuario en su teléfono -> corregir -> cerrar bloque.

## Prohibido

- Agregar mejoras no solicitadas (van a BACKLOG.md).
- Refactorizar fuera del bloque activo.
- Cambiar arquitectura sin autorización.

## Producto

- Solo celular: iPhone y Android. Sencilla: pocas pantallas, registro en
  segundos.
- Montos en pesos chilenos enteros.
- Datos locales en el teléfono (sin servidor) hasta que el usuario decida
  otra cosa.
- iPhone no permite leer notificaciones de otras apps: toda automatización
  debe funcionar también en iPhone (pantallazo + lectura de texto,
  importación de resúmenes), lo exclusivo de Android es un extra.

## Git

- Trabajar en ramas, nunca push directo a `main` sin autorización.
- Ninguna funcionalidad se declara terminada hasta que el usuario la pruebe
  en su teléfono.

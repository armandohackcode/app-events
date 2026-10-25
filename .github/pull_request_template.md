## Qué cambia y por qué

<!-- Issue relacionado: #123 -->

## Checklist de arquitectura

- [ ] La UI no importa Firebase ni `data/`: usa repositorios abstractos de `domain/`
- [ ] Contratos nuevos (datasource/repository) registrados en `lib/config/di/service_locator.dart`
- [ ] `domain/` sigue siendo Dart puro (sin Flutter, Firebase ni `dart:io`)
- [ ] Sin textos, colores, assets ni URLs en duro en la UI: todo sale de `lib/config/theme/`

## Tests

- [ ] Agregué o actualicé tests en la carpeta espejo de `test/`
- [ ] Ningún test nuevo afirma un comportamiento incorrecto; los bugs conocidos van con `skip: 'BUG: ...'`
- [ ] `flutter analyze` y `flutter test` pasan localmente

## Capturas (si cambia la UI)

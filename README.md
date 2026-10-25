# Aplicación para eventos GDG

[![G|GDG Sucre](https://res.cloudinary.com/startup-grind/image/upload/dpr_2.0,fl_sanitize/v1/gcs/platform-data-goog/contentbuilder/logo_dark_QmPdj9K.svg)](https://gdg.community.dev/gdg-sucre/)

[![F|Flutter](https://storage.googleapis.com/cms-storage-bucket/6a07d8a62f4308d2b854.svg)](https://docs.flutter.dev/)

![Badge en Desarrollo](https://img.shields.io/badge/STATUS-EN%20DESAROLLO-green)
[![CI](https://github.com/armandohackcode/app-events/actions/workflows/ci.yml/badge.svg)](https://github.com/armandohackcode/app-events/actions/workflows/ci.yml)

Aplicación móvil desarrollada en Flutter + Firebase para comunidades GDG. Permite a los organizadores gestionar el contenido de sus eventos y ofrece a los asistentes una experiencia enriquecida con agenda, networking por QR, gamificación y una biblioteca de recursos.

El proyecto es de código abierto e inspirado en los guidelines de branding de GDG Community.

---

## Funcionalidades

| Feature | Descripción |
|---|---|
| **Eventos** | Gestión de varios eventos con estado (próximo, activo, finalizado) |
| **Agenda del evento** | Visualización del cronograma con detalle de cada sesión y speaker |
| **Speed Run** | Retos de desarrollo publicados por los organizadores |
| **Gamificación** | Sistema de puntos, ranking de asistentes y treasure hunt |
| **Networking por QR** | Escaneo de QR entre asistentes para conectar y ganar puntos |
| **Biblioteca de recursos** | Materiales, links y recursos compartidos por los organizadores |
| **Panel de administración** | Gestión de contenido dinámico (agenda, speakers, recursos, puntos) |
| **Autenticación** | Inicio de sesión con Google y Apple |

---

## Arquitectura

El proyecto sigue los principios de **Clean Architecture** con el objetivo de mantener un **bajo acoplamiento** entre capas. Cada capa se comunica únicamente a través de contratos abstractos (interfaces), lo que permite cambiar la implementación subyacente (por ejemplo, reemplazar Firebase) sin afectar al resto de la aplicación.

### Capas

```
lib/
├── domain/      ← Reglas de negocio: modelos, interfaces abstractas (datasources y repositories)
├── data/        ← Implementaciones concretas: Firebase (datasources y repositories)
├── ui/          ← Presentación: screens, widgets y providers (state management)
└── config/      ← Configuración transversal: DI (config/di/) y tema (config/theme/)
```

**La capa `domain` no depende de ninguna implementación concreta.** Define los contratos que `data` implementa. La capa `ui` nunca accede a Firebase directamente — solo interactúa con los repositorios abstractos inyectados. Estas reglas se verifican automáticamente en [`test/architecture/`](test/architecture/).

### Configuración centralizada (`lib/config/theme/`)

La UI no tiene textos, colores, assets ni URLs escritos directamente: todo se define en un único lugar.

| Archivo | Contenido |
|---|---|
| `app_strings.dart` | Textos visibles para el usuario (el único lugar con texto en español) |
| `app_styles.dart` | Colores, nombrados por su función (`onAccentColor`, `shadowColor`) y no por su tono |
| `app_assets_path.dart` | Rutas de imágenes e íconos |
| `app_links.dart` | Enlaces externos: comunidad, redes sociales, imágenes de respaldo |

Para cambiar un texto, un color o un enlace, edita la constante correspondiente; nunca el widget.

### Flujo de datos

```
Firebase
  └─→ FirebaseDatasource  (data/datasources/)
        └─→ RepositoryImpl  (data/repositories/)
              └─→ Provider / ChangeNotifier  (ui/providers/)
                    └─→ Widget  (ui/screens/ y ui/widgets/)
```

### State Management

Se utiliza **Provider + ChangeNotifier** como capa de estado. Cada feature tiene su propio provider que actúa como ViewModel:

- `SignInSocialNetworkProvider` — estado de autenticación (Google y Apple, a través de `AuthRepository`)
- `UserProvider` — datos del usuario y perfil del competidor
- `EventProvider` — eventos y evento activo
- `ScheduleProvider` — agenda del evento
- `ResourcesProvider` — biblioteca de recursos
- `SpeedRunProvider` — retos de Speed Run
- `OtherProvider` — organizadores, sponsors y treasure hunt

### Inyección de Dependencias

Se usa **GetIt** como service locator. La configuración está centralizada en [`lib/config/di/service_locator.dart`](lib/config/di/service_locator.dart). Todos los datasources, repositories y providers se registran como lazy singletons o factories, garantizando que ninguna capa instancie sus dependencias directamente.

---

## Prerrequisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.38.1** (Dart `^3.9.2`), la misma versión que usa el CI
- Cuenta de Firebase (plan **Blaze** recomendado para producción)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Android Studio con emulador Android o Xcode con simulador iOS
- [Node.js](https://nodejs.org/) (opcional), para correr el spell check localmente

### Plataformas soportadas

La app se publica **solo para Android, iOS y Web**. Las carpetas `macos/`, `windows/` y `linux/` están ignoradas por git y el CI rechaza cualquier PR que las incluya. Si necesitas probar en escritorio, hazlo localmente sin subir esas carpetas.

---

## Configuración

### 1. Clonar y descargar dependencias

```bash
git clone <url-del-repositorio>
cd app_events
flutter pub get
```

### 2. Configurar variables de entorno

Copia el archivo de ejemplo y reemplaza el valor del Client ID:

```bash
cp lib/env_example.dart lib/env.dart
```

Abre `lib/env.dart` y reemplaza `SERVICE_CLIENT_ID` con el **Web Client ID** de tu proyecto Firebase (lo encuentras en Firebase Console → Authentication → Método de acceso → Google → ID de cliente web):

```dart
final String serviceClientId = 'TU_CLIENT_ID.apps.googleusercontent.com';
```

> Este valor es necesario para la autenticación con Google. Sin él, la app no compilará.

### 3. Crear y configurar el proyecto Firebase

Desde la [consola de Firebase](https://console.firebase.google.com/), crea un nuevo proyecto y activa los siguientes servicios:

- **Authentication** — habilita los proveedores Google y Apple
- **Cloud Firestore** — base de datos en tiempo real
- **Firebase Storage** — almacenamiento de imágenes

### 4. Vincular Firebase con la app

```bash
# Instalar la CLI de FlutterFire (solo la primera vez)
dart pub global activate flutterfire_cli

# Vincular el proyecto Firebase y generar firebase_options.dart
flutterfire configure
```

Selecciona solo las plataformas soportadas (**Android, iOS y Web**); no marques macOS, Windows ni Linux. El archivo `firebase_options.dart` se genera automáticamente.

> **Nunca subas archivos de configuración al repositorio.** `lib/env.dart`, `lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`, `key.properties` y los keystores están en `.gitignore`, y el CI falla si alguno queda versionado. El repositorio es público.

### 5. Ejecutar la aplicación

```bash
flutter run
```

> **Nota sobre costos:** En producción con uso masivo, el plan gratuito de Firebase puede generar costos. Se recomienda añadir una tarjeta al plan Blaze y configurar alertas de presupuesto en la consola de Firebase.

---

## Configuración de Firestore

La mayoría de las colecciones se crean automáticamente cuando los usuarios interactúan con la app. Las siguientes deben configurarse **manualmente** antes del primer uso:

### Colección `users-admin`

Define quiénes tienen rol de administrador. Crea un documento por cada admin con el UUID del usuario autenticado (lo encuentras en **Firebase Console → Authentication → Users**).

```json
{
  "name": "Nombre del administrador",
  "uuid": "UID_DEL_USUARIO_EN_FIREBASE"
}
```

### Colección `organizers`

Registra a los organizadores del evento que aparecerán en la pantalla principal.

```json
{
  "name": "Nombre del organizador",
  "photoUrl": "https://ejemplo.com/foto.png",
  "link": "https://github.com/usuario",
  "type": 1
}
```

| Valor `type` | Rol |
|---|---|
| `1` | Organizer |
| `2` | Lead Organizer |

---

## Roles de usuario

| Rol | Capacidades |
|---|---|
| **Participante** | Ver agenda · Networking QR · Ranking · Biblioteca de recursos · Treasure hunt |
| **Administrador** | Todo lo anterior + Gestionar eventos · Agregar speakers · Agregar recursos · Gestionar sponsors · Agregar retos de Speed Run · Ver lista de participantes · Regalar puntos |

---

## Tests

Los tests replican la estructura de `lib/` dentro de `test/`:

| Tipo | Carpeta | Qué verifica |
|---|---|---|
| Arquitectura | `test/architecture/` | Dependencias entre capas, registro en el service locator y que la UI no tenga textos, colores, assets ni URLs escritos directamente |
| Dominio | `test/domain/` | Serialización de modelos con Firestore (`fromJson`/`toJson`) y valores por defecto |
| Datos | `test/data/` | Repositorios (con `mocktail`) y datasources contra un Firestore en memoria (`fake_cloud_firestore`) |
| Providers | `test/ui/providers/` | Estados de carga, errores y orden de las operaciones |
| Widgets | `test/ui/widgets/` | Lo que el usuario ve y puede hacer |

```bash
flutter test                      # suite completa
flutter test test/architecture    # solo reglas de arquitectura

# Cobertura (incluye los archivos sin tests como 0%)
./tool/ci/coverage_helper.sh && flutter test --coverage
./tool/ci/check_coverage.sh coverage/lcov.info 14
```

**Los tests describen el comportamiento correcto, nunca un bug.** Si encuentras un bug, escribe el test con el comportamiento esperado y márcalo con `skip: 'BUG: <descripción>'` hasta corregirlo. El CI lista esos tests en el resumen de cada ejecución.

---

## Integración continua

Cada PR hacia `main` ejecuta [`ci.yml`](.github/workflows/ci.yml):

1. **Calidad:** spell check (código, comentarios y tests en inglés), `dart format`, `flutter analyze --fatal-infos`, que no haya archivos de configuración versionados y que solo existan las plataformas soportadas.
2. **Tests:** arquitectura, suite completa y cobertura mínima. La cobertura mínima (`MIN_COVERAGE`) solo puede subir.
3. **Build:** APK de debug.

Además, [`pr-checks.yml`](.github/workflows/pr-checks.yml) exige un nombre de rama válido (`feature/`, `fix/`, `hotfix/`, `refactor/`, `test/`, `docs/`, `chore/` o `ci/`) y una descripción en el PR, usando la [plantilla](.github/pull_request_template.md).

El CI compila con archivos de configuración de prueba. Para compilar con el proyecto real de Firebase, define en GitHub los secrets opcionales `FIREBASE_OPTIONS_DART_B64`, `ENV_DART_B64` y `GOOGLE_SERVICES_JSON_B64` (cada archivo codificado en base64).

---

## Trabajo con Claude Code

El repositorio incluye configuración para [Claude Code](https://claude.com/claude-code):

- [`CLAUDE.md`](CLAUDE.md): reglas del proyecto que Claude lee en cada sesión.
- **Hooks** ([`.claude/`](.claude/settings.json)): formatean el código, bloquean violaciones de arquitectura y valores escritos directamente, protegen los archivos de configuración, impiden crear plataformas de escritorio y no permiten que Claude haga commits. Antes de terminar cada tarea, corren las mismas verificaciones que el CI.
- **Skills:** `/new-feature` (crear una feature completa por capas), `/write-tests` (tests según las convenciones) y `/architecture-review` (revisar una rama antes del PR).

---

## Contribuir

El proyecto está abierto a contribuciones. Para orientarte rápidamente en el código, ten en cuenta:

1. **Crea una rama** con el prefijo adecuado, por ejemplo `feature/42-encuestas` o `fix/login-spinner`.
2. **Agrega una feature nueva** siguiendo las capas: modelo en `domain/models/`, contrato en `domain/datasources/` y `domain/repositories/`, implementación Firebase en `data/`, provider en `ui/providers/`, y UI en `ui/screens/` o `ui/widgets/`.
3. **Registra las nuevas dependencias** en `lib/config/di/service_locator.dart`.
4. **No acoples la UI a Firebase directamente** — toda la lógica de acceso a datos debe ir a través del repositorio correspondiente.
5. **Centraliza textos, colores, assets y enlaces** en `lib/config/theme/`.
6. **Agrega tests** en la carpeta espejo de `test/` y verifica antes de abrir el PR:

   ```bash
   dart format lib test && flutter analyze && flutter test
   ```

7. **Completa la plantilla del PR**, incluido el checklist de arquitectura.

---

## Licencia

[Apache 2.0](LICENCE.md)

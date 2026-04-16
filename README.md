# Aplicación para eventos GDG

[![G|GDG Sucre](https://res.cloudinary.com/startup-grind/image/upload/dpr_2.0,fl_sanitize/v1/gcs/platform-data-goog/contentbuilder/logo_dark_QmPdj9K.svg)](https://gdg.community.dev/gdg-sucre/)

[![F|Flutter](https://storage.googleapis.com/cms-storage-bucket/6a07d8a62f4308d2b854.svg)](https://docs.flutter.dev/)

![Badge en Desarrollo](https://img.shields.io/badge/STATUS-EN%20DESAROLLO-green)

Aplicación móvil desarrollada en Flutter + Firebase para comunidades GDG. Permite a los organizadores gestionar el contenido de sus eventos y ofrece a los asistentes una experiencia enriquecida con agenda, networking por QR, gamificación y una biblioteca de recursos.

El proyecto es de código abierto e inspirado en los guidelines de branding de GDG Community.

---

## Funcionalidades

| Feature | Descripción |
|---|---|
| **Agenda del evento** | Visualización del cronograma con detalle de cada sesión y speaker |
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
└── config/      ← Configuración transversal: DI, tema, rutas, assets
```

**La capa `domain` no depende de ninguna implementación concreta.** Define los contratos que `data` implementa. La capa `ui` nunca accede a Firebase directamente — solo interactúa con los repositorios abstractos inyectados.

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

- `SignInSocialNetworkProvider` — estado de autenticación
- `UserProvider` — datos del usuario y perfil del competidor
- `ScheduleProvider` — agenda del evento
- `ResourcesProvider` — biblioteca de recursos
- `OtherProvider` — organizadores, sponsors y treasure hunt

### Inyección de Dependencias

Se usa **GetIt** como service locator. La configuración está centralizada en [`lib/config/di/service_locator.dart`](lib/config/di/service_locator.dart). Todos los datasources, repositories y providers se registran como lazy singletons o factories, garantizando que ninguna capa instancie sus dependencias directamente.

---

## Prerrequisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.9.2`)
- Cuenta de Firebase (plan **Blaze** recomendado para producción)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Android Studio con emulador Android o Xcode con simulador iOS

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

Selecciona las plataformas que necesites (Android, iOS). El archivo `firebase_options.dart` se genera automáticamente.

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
| **Administrador** | Todo lo anterior + Agregar speakers · Agregar recursos · Ver lista de participantes · Regalar puntos |

---

## Contribuir

El proyecto está abierto a contribuciones. Para orientarte rápidamente en el código, ten en cuenta:

1. **Agrega una feature nueva** siguiendo las capas: modelo en `domain/models/`, contrato en `domain/datasources/` y `domain/repositories/`, implementación Firebase en `data/`, provider en `ui/providers/`, y UI en `ui/screens/` o `ui/widgets/`.
2. **Registra las nuevas dependencias** en `lib/config/di/service_locator.dart`.
3. **No acoples la UI a Firebase directamente** — toda la lógica de acceso a datos debe ir a través del repositorio correspondiente.

---

## Licencia

[Apache 2.0](LICENCE.md)

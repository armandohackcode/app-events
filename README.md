# Aplicación para eventos GDG

[![G|GDG Sucre](https://res.cloudinary.com/startup-grind/image/upload/dpr_2.0,fl_sanitize/v1/gcs/platform-data-goog/contentbuilder/logo_dark_QmPdj9K.svg)](https://gdg.community.dev/gdg-sucre/)

[![F|FLutter](https://storage.googleapis.com/cms-storage-bucket/6a07d8a62f4308d2b854.svg)](https://docs.flutter.dev/)


Este es un proyecto desarrollado en Flutter con Firebase, cuyo enfoque principal es el proporcionar un entorno en donde se pueda informar los detalles de los eventos de la comunidad GDG Sucre y adicionalmente tener un mecanismo para hacer networking entre los asistentes a los eventos basado en una interacción a través de código QR y competncia por puntos, en este ejemplo se ha utilizado un diseño propio inspirado en el branding guidelines proporcionado por el programa de GDG community, el proyecto fué desarrollado con el unico propósito de mojarar la experiencia de los asistentes a los eventos de la GDG Sucre y es de código abierto.

![Badge en Desarollo](https://img.shields.io/badge/STATUS-EN%20DESAROLLO-green)
## Empezar
Este proyecto es un punto de partida para una aplicación Flutter.
Algunos recursos para comenzar si este es su primer proyecto de Flutter:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

Para obtener ayuda para comenzar con el desarrollo de Flutter, consulte el
[documentación en línea](https://docs.flutter.dev/), que ofrece tutoriales,
muestras, orientación sobre desarrollo móvil y una referencia completa de la API.
```
# para descargar todos los paquetes del proyecto
flutter pub get
```

## Configuración
Es necesario hacer la configuración y la vinculación con una cuenta de firebase particular, y utilizar las firmas correspondientes de autorización de tu cuenta.
 - [Consulta la documentación Flutter con Firebase](https://firebase.flutter.dev/docs/overview)

#### Instala Firebase CLI con dart
Mediante el comando `flutterfire configure` selecciona el proyecto de firebase existen con el cual trabajarás o en su defecto crea uno nuevo, seleciona para que entornos obtendras la configuración 
"android, IOS, MacOS, Linux, Windons, Web", NOTA : la aplicación solo esta pensada para entorno mobile Andriod, IOS, si se desea adaptar el diseño para otros entornos, se debe pensar en considerar diseño responsivo.
```
# Install the CLI if not already done so
dart pub global activate flutterfire_cli
# Run the `configure` command, select a Firebase project and platforms
flutterfire configure
```
con el proyecto vinculado y previamente descargado los paquetes de flutter, solo queda ejecutar el proyecto. 
```
flutter run
```

`Nota: si se desea utilizar el proyecto en un entorno en producción debe preveer los gasto por el uso de firestore, añadiendo una tarjeta a la cuenta Blaze, debido a que el uso masivo podría ocasiónar costos en algun punto.`

#### Controles
Dentro de la aplicaicón existen dos roles, uno de administrador y participante, el usuario administrador tienes mas opciones para controlar el contenido dinámico dentro de la aplicación.
- Añadir nuevos speakers
- Añadir recursos
- Ver lista de Participantes
- Regalar puntos a los participantes

Para habilitar un usuario como administrador se necesita hacer un proceso manual
donde se necesista el `uuid` del usuario autentificado en firebase (buscar en el apartador de Usuarios authentificados de Firesase)
y añadir la siguiente colección en firestore
crea una collection con el nombre de `users-admin` y añade un document con el siguiente formato
```
{
    "name":"Cantinflas el Padrecito",
    "uuid": uuidEXAMPLELasdadsasdasdafdsdf
}
```
##### Añadir organizers
Los organizers del evento se registran de forma manual por el momento, directamente desde firestore.
Crea una collection con el nombre de `organizers` y añade por cada organizador un nuevo documeto con los siguientes datos y formato.
```
{
    "name":"El chavo",
    "photoUrl":"https://example.com/img-fulanot.png",
    "link":"https://github.com/armandohackcode",
    "type": 1
    
}
/// type 1: organizer
/// type 2: Lead Organizer
```



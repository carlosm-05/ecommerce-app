# Mi Tienda - Flutter

Aplicación móvil de comercio electrónico. La app Flutter está en la raíz y el backend Spring Boot local está en `backend-source/`.

## Requisitos

- Flutter 3.29 o posterior y Dart compatible con `pubspec.yaml`.
- Android Studio con Android SDK y un emulador configurado, o un dispositivo Android con depuración USB.
- Java 17 o posterior para ejecutar el backend local.

Comprueba la instalación de Flutter y Android con:

```powershell
flutter doctor -v
```

## Ejecutar en Android con el backend local

1. En una terminal, inicia la API. La configuración predeterminada usa una base H2 local y carga datos de demostración:

   ```powershell
   Set-Location backend-source
   .\mvnw.cmd spring-boot:run
   ```

   La API queda disponible en `http://localhost:8080`. Consulta `backend-source/README.md` para opciones de Docker o bases de datos.

2. En otra terminal, desde la raíz del proyecto, descarga dependencias y ejecuta la app:

   ```powershell
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   ```

   `10.0.2.2` es la dirección del equipo anfitrión vista desde el emulador Android. La app usa esa URL local por defecto, por lo que también puedes ejecutar `flutter run` sin definirla.

### Dispositivo Android físico

Conecta el teléfono y el computador a la misma red Wi-Fi. Averigua la dirección IPv4 del computador y úsala en vez de `10.0.2.2`, por ejemplo:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Permite conexiones entrantes al puerto `8080` en el firewall del computador si el teléfono no alcanza la API. No uses `localhost` en el teléfono: se refiere al propio teléfono.

## Compilar un APK de depuración

Con el backend no necesariamente activo, compila el APK:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

El archivo se genera en `build/app/outputs/flutter-apk/app-debug.apk`. Para ejecutarlo en Android Studio, abre la carpeta del proyecto, espera la sincronización de Gradle y selecciona un emulador o dispositivo Android.

## Pruebas y análisis

```powershell
flutter test
flutter analyze
```

La URL del backend se configura con `--dart-define=API_BASE_URL=...`; el valor predeterminado está pensado para el emulador Android y no contiene credenciales.

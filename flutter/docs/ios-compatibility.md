# Compatibilidad iOS — Hito 1

EnergyCore mantiene una sola aplicación Flutter para Android e iOS. Las pantallas,
controladores, repositorios, traducciones y contratos REST son compartidos; no se
ha creado una aplicación iOS independiente.

## Adaptación implementada

- Proyecto Xcode en `ios/`, generado con Flutter 3.44.8; destino mínimo iOS 13.
- Identificador `com.teralume.energycoreFlutter`, nombre EnergyCore e iconos propios.
- El canal `com.teralume.energycore/secure_storage` conserva los métodos `read`,
  `write` y `clear`. Android usa Keystore; iOS usa Keychain con
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. No se guardan JWT en preferencias.
- La API predeterminada es HTTPS:
  `https://energycore-platform-624519427815.us-east1.run.app/api/v1`.
  `API_BASE_URL` permite cambiar el entorno. No se permiten conexiones HTTP
  arbitrarias mediante excepciones de App Transport Security.
- Se conserva la navegación adaptable de Flutter y los idiomas EN/ES/PT.

## Evidencia y límites

Las 11 pruebas Flutter pasan, incluida la apertura de autenticación sin sesión a
393 × 852 con `TargetPlatform.iOS`. Esa prueba ejecuta widgets con almacenamiento
simulado: no acredita el motor UIKit, Keychain ni una ejecución en iPhone.
Se incluye un XCTest para lectura, actualización, persistencia entre instancias y
borrado del token en Keychain, pendiente de ejecución interactiva con Xcode.

GitHub Actions ejecutó `flutter build ios --simulator --debug` correctamente en
un runner macOS y publicó `Runner.app` como artefacto. Por tanto, el estado es
**compatibilidad y compilación para simulador verificadas; Keychain y ejecución
interactiva en un iPhone físico no verificadas**. No se presenta un IPA ni
capturas Android como evidencia iOS.

## Validación interactiva pendiente en macOS

Con Flutter 3.44.8 y Xcode configurados, desde la carpeta `flutter`:

```sh
flutter pub get
flutter analyze
flutter test
flutter build ios --simulator --debug
open ios/Runner.xcworkspace
```

En Xcode, seleccionar un simulador iPhone y ejecutar Product → Test para RunnerTests.
Ejecutar la app, iniciar sesión con una cuenta de prueba, cerrarla y abrirla para
comprobar la restauración de sesión; cerrar sesión y confirmar que ya no se restaura.
Comprobar navegación, teclado, áreas seguras, tema e idioma. En un iPhone físico
se requiere configurar la firma del equipo en Xcode; no se configura una cuenta
Apple ni distribución App Store como parte de este incremento.

Referencia: https://docs.flutter.dev/platform-integration/ios

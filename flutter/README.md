# EnergyCore Mobile — Flutter

Cliente móvil de EnergyCore. Consume la API REST existente de `energycore-platform`; no crea ni mantiene una base de datos de producto separada.

## Pruebas y CI/CD

Cada `push` y Pull Request ejecuta formato, análisis estático, pruebas unitarias,
pruebas de widgets y compatibilidad, y genera un APK release. Un job adicional
en macOS compila la aplicación para el simulador iOS. Los binarios verificados
y el reporte de cobertura quedan disponibles como artefactos de GitHub Actions.

```powershell
flutter pub get
flutter analyze
flutter test --coverage
flutter build apk --release
```

## Alcance implementado

- Autenticación: inicio de sesión, registro, recuperación, restablecimiento por
  token y cierre de sesión.
- Inicio operativo conectado: consumo actual, sedes, dispositivos, grupos, rutinas, modos, alertas, metas y soporte.
- Energía: tablero en vivo, historial de lecturas, reportes por rango y metas energéticas.
- Operaciones: alta, vinculación, edición, control y baja de dispositivos;
  grupos; rutinas por dispositivo, grupo, habitación o sede con recurrencia;
  y modos con alcance, ventana horaria, metas, perfiles de alerta, rutinas
  internas, vista previa, activación y archivo.
- Alertas: creación manual, filtros, detalle, resolución, descarte, reglas,
  perfiles de reglas, evaluación y preferencias multicanal.
- Espacios: sedes con búsqueda de direcciones, habitaciones y asignaciones de
  dispositivos con movimiento entre espacios.
- Servicio: solicitudes de soporte y mantenimientos programados.
- Facturación: planes, checkout, suscripción actual, pagos y exportación de
  comprobantes.
- Cuenta: perfil, seguridad, accesos y descripción de plataforma.
- Inglés, español y portugués; tema de sistema, claro u oscuro sincronizado con
  las preferencias del backend.
- Permisos por perfil, acceso condicionado a suscripción y límites por plan.
- Sesión JWT mediante Android Keystore (AES/GCM) o iOS Keychain.
- Aviso persistente sin conexión y acción `Reintentar`.
- Ícono y pantalla de arranque Android propios de EnergyCore, sin recursos
  visuales azules del proyecto Flutter predeterminado en uso.

La correspondencia de las 30 páginas del frontend web está documentada en
[`docs/web-parity.md`](docs/web-parity.md).

## Ejecutar en el emulador Android

La ruta real contiene caracteres que algunas herramientas Android no procesan correctamente en Windows. Asígnala a una unidad ASCII antes de ejecutar:

```powershell
subst M: "C:\JeanLoa\Universidad\Diseño de Experimentos de Ingeniería de Software\energycore-mobile\flutter"
Set-Location M:\
& "C:\JeanLoa\SDKs\flutter\bin\flutter.bat" pub get
& "C:\JeanLoa\SDKs\flutter\bin\flutter.bat" run -d emulator-5554
```

La aplicación usa la API pública HTTPS de EnergyCore de forma predeterminada. Para desarrollo local Android, especificar `--dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1`.

Para usar otra API:

```powershell
& "C:\JeanLoa\SDKs\flutter\bin\flutter.bat" run -d emulator-5554 --dart-define=API_BASE_URL="https://api.example.com/api/v1"
```

## Compatibilidad iOS

La misma aplicación Flutter incluye el proyecto Xcode y la integración con Keychain.
Consulta [alcance, evidencia y ejecución iOS](docs/ios-compatibility.md).
La compilación para simulador iOS está verificada mediante GitHub Actions en macOS.
La ejecución interactiva y Keychain en un iPhone físico permanecen pendientes.

## Pruebas compartidas

```powershell
& "C:\JeanLoa\SDKs\flutter\bin\dart.bat" analyze
& "C:\JeanLoa\SDKs\flutter\bin\flutter.bat" test
```

## Arquitectura

Cada bounded context separa `domain`, `application`, `infrastructure` y `presentation`. Los componentes compartidos de red, almacenamiento seguro y presentación están en `lib/shared/`; el shell adaptativo autenticado está en `lib/shell/`.

- `lib/iam/`
- `lib/energy_monitoring/`
- `lib/device_control/`
- `lib/workplace/`
- `lib/notifications/`
- `lib/reporting/`
- `lib/service_management/`
- `lib/billing/`
- `lib/shared/`
- `lib/shell/`

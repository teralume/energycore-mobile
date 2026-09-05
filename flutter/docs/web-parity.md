# Paridad funcional Web → Flutter

Referencia auditada: las 30 páginas Angular de `energycore-webapp/src/app`.
La implementación móvil conserva los contratos REST y adapta la navegación a
teléfono/tablet sin copiar la estructura visual de escritorio literalmente.

| Contexto | Página web | Equivalente Flutter | Acciones cubiertas |
|---|---|---|---|
| IAM | Login | `AuthPage` | inicio de sesión, validación, sesión JWT |
| IAM | Register | `AuthPage` | registro y validación de contraseña |
| IAM | Recover password | `AuthPage` | solicitud de correo de recuperación |
| IAM | Reset password | `AuthPage` | token, contraseña y confirmación |
| IAM | Profile | `AccountPage / Profile` | consulta y edición |
| IAM | Account | `AccountPage` | perfil y eliminación de cuenta |
| IAM | Security | `AccountPage / Security` | recuperación segura y eliminación |
| IAM | Access | `AccountPage / Access` | usuarios, perfiles, permisos y asignación |
| IAM | Platform | `AccountPage / Platform` | capacidades y versión |
| Shared | Home | `HomeOverviewPage` | resumen conectado y progreso de puesta en marcha |
| Shared | About | `AccountPage / Platform` | producto, Teralume y universidad |
| Shared | Not found | navegación tipada nativa | no existen URLs internas inválidas |
| Energy | Dashboard | `EnergyDashboardPage` | consumo, costo, eficiencia, tendencia, rankings y exportación CSV |
| Energy | History | `EnergyHubPage / History` | filtros, rango, orden, paginación y muestreo |
| Devices | Devices | `DeviceControlPage / Devices` | alta, vinculación, edición, control y baja |
| Devices | Groups | `DeviceControlPage / Groups` | alta, edición, encendido/apagado y baja |
| Devices | Routines | `DeviceControlPage / Routines` | objetivos por dispositivo, grupo, habitación o sede; repetición única, diaria, semanal o por intervalo; ejecución, activación y baja |
| Devices | Operation modes | `DeviceControlPage / Modes` | alcance por sede/habitación, horario, metas, perfiles, preferencias, rutinas internas, vista previa, activación y archivo |
| Workplace | Locations | `WorkplacePage / Sites` | alta, edición, baja y búsqueda OpenStreetMap |
| Workplace | Rooms | `WorkplacePage / Rooms` | alta, edición y baja |
| Workplace | Assignments | `WorkplacePage / Assignments` | asignar, mover y desasignar dispositivos |
| Notifications | Alerts | `NotificationsPage / Inbox` | alta manual, filtros, detalle, leer, resolver, descartar y borrar |
| Notifications | Alert rules | `NotificationsPage / Rules` | alta, activación, perfiles, evaluación y baja |
| Notifications | Preferences | `NotificationsPage / Preferences` | canales, nivel, agrupación, recordatorios y límites |
| Reporting | Reports | `EnergyHubPage / Reports` | generación, detalle, actividad, exportación y baja |
| Reporting | Energy goals | `EnergyHubPage / Goals` | alta, edición, progreso y baja |
| Service | Support tickets | `ServicePage / Support` | alta, seguimiento, cierre y baja |
| Service | Maintenance tickets | `ServicePage / Maintenance` | programación, finalización y baja |
| Billing | Plans | `BillingPage / Plans` | catálogo, checkout, plan actual y cancelación |
| Billing | Billing history | `BillingPage / Payments + Invoices` | pagos y exportación de comprobante |

## Reglas transversales conservadas

- Barrera de sesión y de suscripción activa antes del shell operativo.
- Permisos equivalentes para `OWNER`, `ADMIN`, `MEMBER` y `GUEST`.
- Límites de plan para dispositivos, rutinas, alertas, historial, exportación y
  múltiples sedes.
- Preferencias de idioma y tema sincronizadas con
  `/users/me/ui-preferences`.
- Aviso persistente de desconexión con acción de reintento.
- API de producto única en `energycore-platform`; OpenStreetMap solo resuelve
  texto de direcciones y no mantiene datos de negocio.
- Exportaciones adaptadas a móvil mediante el portapapeles para que el usuario
  pueda guardarlas o compartirlas desde el sistema.

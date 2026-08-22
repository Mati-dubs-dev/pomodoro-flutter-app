# Arquitectura de Pomodoro Pro

Este documento permite modificar el proyecto sin romper la restauración del temporizador ni las estadísticas.

## Capas

### Interfaz

Las pantallas de `lib/screens` observan providers y envían acciones al notifier. Los widgets reutilizables viven en `lib/widgets`. La interfaz no escribe directamente en SharedPreferences ni programa notificaciones.

### Estado y reglas de negocio

`PomodoroNotifier` coordina modo, tiempo restante, tarea, ciclos y finalización. También decide cuándo persistir, emitir señales de finalización o iniciar automáticamente el siguiente modo.

`StatsProvider` transforma el historial en métricas: semana actual y anterior, racha, mejor día y agrupación por tarea.

### Servicios

- `TimerService` mantiene el reloj y calcula el tiempo restante usando una fecha de finalización.
- `StorageService` administra preferencias, snapshots, estadísticas e historial.
- `NotificationService` solicita permisos y programa o cancela avisos.
- `AudioService` y `HapticService` aíslan efectos secundarios opcionales.

Las interfaces permiten sustituir servicios reales por fakes en pruebas.

## Modelos persistidos

`TimerSnapshot` representa un temporizador activo o pausado. Contiene modo, tarea, estado de pausa, segundos restantes y fecha de finalización cuando corresponde.

`FocusSession` representa una sesión completada: identificador, fecha, minutos y tarea. El historial se limita a 300 elementos.

`DailyStat` almacena agregados por fecha. Se conservan hasta 90 días y el cambio de día archiva los contadores anteriores antes de iniciar el nuevo registro.

Al modificar modelos, conserva valores por defecto para claves ausentes y considera los datos escritos por versiones anteriores.

## Ciclo del temporizador

1. El usuario selecciona un modo e inicia la sesión.
2. El notifier calcula la hora de finalización y guarda un snapshot.
3. El servicio actualiza la interfaz a partir del reloj actual.
4. Una pausa reemplaza la fecha por segundos restantes.
5. Al reanudar se calcula una nueva fecha de finalización.
6. Al completar foco se registra la sesión y se actualizan estadísticas.
7. La política de inicio automático decide el siguiente modo.

Al arrancar, un snapshot vencido se reconcilia una sola vez. Esto evita perder sesiones terminadas con la aplicación cerrada y evita contarlas dos veces.

## Notificaciones

Se programan al iniciar o reanudar y se cancelan al pausar, reiniciar, saltar o cambiar de modo. Android intenta alarmas exactas y utiliza programación inexacta si el sistema no lo permite.

Los permisos se solicitan como consecuencia de una acción del usuario. Una plataforma nueva debe implementar la interfaz sin introducir dependencias en la lógica central.

## Estrategia de pruebas

Las pruebas inyectan un reloj controlado, un driver de temporizador y servicios falsos. Así pueden avanzar el estado sin esperar minutos reales y verificar notificaciones, audio y persistencia.

Los cambios en finalización, restauración, cambio de fecha o historial deben incluir una prueba de regresión.

## Principios para cambios futuros

- Mantener la lógica determinista y separada de la interfaz.
- Tratar almacenamiento y notificaciones como efectos externos inyectables.
- Usar tiempo absoluto en lugar de depender solo de ticks.
- Mantener compatibilidad hacia atrás en datos persistidos.
- Considerar accesibilidad, pantallas compactas y diferencias de plataforma.
- Documentar permisos nuevos y su impacto en privacidad.

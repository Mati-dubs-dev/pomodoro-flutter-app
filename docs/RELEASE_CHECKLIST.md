# Checklist de lanzamiento

## Calidad

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build web --release`
- [ ] `flutter build appbundle --release`
- [ ] `flutter build ipa --release` desde macOS

## Pruebas en dispositivos reales

- [ ] Android 13 o posterior: aceptar y rechazar notificaciones
- [ ] iPhone: aceptar y rechazar notificaciones
- [ ] Iniciar, pausar, reanudar, reiniciar y saltar cada modo
- [ ] Bloquear pantalla y comprobar el aviso al finalizar
- [ ] Cerrar la app durante una sesión y abrirla antes y después del final
- [ ] Reiniciar un Android durante una sesión y comprobar reprogramación
- [ ] Completar una sesión antes y después de medianoche
- [ ] Validar sonido, vibración y notificación por separado
- [ ] Probar texto del sistema al 200 %, lector de pantalla y orientación

## Identidad y tiendas

- [ ] Confirmar `com.matidubs.pomodoropro` como identificador definitivo
- [ ] Crear y guardar de forma segura el keystore de Android
- [ ] Configurar firma de distribución y perfiles de iOS
- [ ] Preparar capturas, descripción, política de privacidad y correo de soporte
- [ ] Revisar categorías de privacidad: los datos permanecen en el dispositivo
- [ ] Incrementar `version` en `pubspec.yaml`

## Publicación gradual

- [ ] Publicar primero en canal interno/TestFlight
- [ ] Validar notificaciones en distintos fabricantes Android
- [ ] Revisar errores y comentarios antes de producción
- [ ] Conservar una versión anterior para rollback

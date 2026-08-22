# Guía de contribución

Gracias por tu interés en mejorar Pomodoro Pro. Esta guía explica cómo proponer cambios fáciles de revisar y mantener.

## Antes de comenzar

- Revisa los issues abiertos para evitar trabajo duplicado.
- Para cambios grandes, abre primero un issue y describe el problema, la solución y sus efectos por plataforma.
- No incluyas credenciales, certificados, claves de firma ni datos personales.
- Respeta el [Código de conducta](CODE_OF_CONDUCT.md).

## Preparar el entorno

```bash
git clone https://github.com/Mati-dubs-dev/pomodoro-flutter-app.git
cd pomodoro-flutter-app
flutter pub get
flutter doctor -v
```

Crea una rama descriptiva desde `main`:

```bash
git switch main
git pull --ff-only
git switch -c feat/nombre-del-cambio
```

Prefijos sugeridos: `feat/`, `fix/`, `docs/`, `test/`, `refactor/` y `chore/`.

## Convenciones

- Sigue `analysis_options.yaml` y formatea los archivos Dart.
- Mantén las reglas de negocio fuera de los widgets cuando sea posible.
- Inyecta reloj y servicios externos para poder probar sin esperas reales.
- Conserva la compatibilidad al cambiar modelos persistidos.
- Comprueba accesibilidad y tamaños compactos al modificar la interfaz.
- No confirmes `build/`, `.dart_tool/`, archivos del IDE ni secretos.
- No edites registrantes de plugins manualmente; regénéralos con Flutter.

## Verificación obligatoria

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Si el cambio afecta una plataforma concreta, compílala y describe la prueba manual. Los cambios de notificaciones, restauración o fecha deben probarse también en un dispositivo real.

## Commits

Usa mensajes breves en modo imperativo, por ejemplo:

```text
feat: add session export
fix: restore paused timer after restart
docs: explain Android notification permissions
test: cover midnight rollover
```

Evita mezclar reformateos masivos o archivos no relacionados.

## Pull requests

Completa la plantilla e incluye el problema, la solución, las pruebas realizadas, las plataformas afectadas y capturas si cambia la interfaz. Documenta migraciones, riesgos o incompatibilidades. Los mantenedores pueden solicitar dividir cambios demasiado amplios.

## Reportar errores

Incluye pasos reproducibles, resultado esperado y actual, plataforma, versiones y salida relevante de `flutter doctor -v`. Elimina datos personales de los registros.

## Proponer funciones

Explica primero el caso de uso. Indica si la propuesta modifica datos, permisos, privacidad, accesibilidad o comportamiento entre plataformas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_pro/providers/pomodoro_provider.dart';
import 'package:pomodoro_pro/screens/pomodoro_screen.dart';
import 'package:pomodoro_pro/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('la pantalla principal se adapta a una altura compacta', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'haptics_enabled': false});
    final storage = await StorageService.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          timerServiceProvider.overrideWithValue(FakeTimerDriver()),
          audioServiceProvider.overrideWithValue(FakeAudio()),
          notificationServiceProvider.overrideWithValue(FakeNotifications()),
        ],
        child: const MaterialApp(home: PomodoroScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('¿En qué vas a enfocarte?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

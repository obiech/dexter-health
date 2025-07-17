import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shift_handover_challenge/core/di/injection_container.dart'
    as di;
import 'package:shift_handover_challenge/core/theme/theme.dart';
import 'package:shift_handover_challenge/features/shift_handover/presentation/shift_handover_screen.dart';

void main() async {
  /// Captures errors reported by the Flutter framework.

  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In development mode, simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };

  /// Captures errors reported by the native environment, including native iOS
  /// and Android code.
  Future<void> reportError(dynamic error, StackTrace stackTrace) async {
    // Print the exception to the console.
    if (kDebugMode) {
      // Print the full stacktrace in debug mode.
      log(error.toString(), stackTrace: stackTrace);
      return;
    } else {
      // Send the Exception and Stacktrace to sentry in Production mode.
    }
  }

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await di.init();

    runApp(const MyApp());
  }, reportError);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final AppRouter appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift Handover',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ShiftHandoverScreen(),
      // routeInformationParser: appRouter.defaultRouteParser(),
      // routerDelegate: appRouter.delegate(
      //   initialRoutes: [const ShiftHandoverRoute()],
      // ),
    );
  }
}

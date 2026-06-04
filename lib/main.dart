import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/theme.dart';
import 'presentation/pages/dashboard_page.dart';

void main() {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    const ProviderScope(
      child: ArclogApp(),
    ),
  );
}

/// ScrollBehavior personnalisé : active la souris (drag + roue) sur tous
/// les scrollables de l'app, y compris les listes horizontales.
class _ArclogScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class ArclogApp extends StatelessWidget {
  const ArclogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARCLOG',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _ArclogScrollBehavior(),
      theme: ArclogTheme.dark.copyWith(
        textTheme: GoogleFonts.orbitronTextTheme(ArclogTheme.dark.textTheme),
      ),
      home: const DashboardPage(),
    );
  }
}

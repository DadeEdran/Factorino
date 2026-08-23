import 'package:flutter/material.dart';

import 'data/database/app_database.dart';
import 'data/database/database_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Startup opens the encrypted database and asserts, against the bytes on
  // disk, that it really is encrypted (D-020). A failure here is deliberately
  // fatal: the alternative is running on a plaintext database holding
  // financial records and third-party national IDs.
  //
  // The Persian failure screen this deserves arrives with the localization
  // layer; until then the exception is unhandled, which is loud and honest
  // rather than a silently degraded start.
  final AppDatabase database = await openAppDatabase();

  runApp(FactorinoApp(database: database));
}

/// Placeholder root.
///
/// Intentionally renders nothing: the theme, localization, RTL setup, router
/// and navigation shell are later increments of Phase 1, and a temporary
/// English scaffold would violate the zero-English-user-facing-text rule
/// on its way to being deleted.
class FactorinoApp extends StatelessWidget {
  const FactorinoApp({required this.database, super.key});

  /// Held so the connection stays open for the process lifetime. The next
  /// increment exposes it through a Riverpod provider instead.
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: SizedBox.shrink()),
    );
  }
}

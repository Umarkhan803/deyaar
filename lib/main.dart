import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/app_repository.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = AppRepository();
  final provider = AppProvider(repo);
  await provider.init();
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const DeyaarApp(),
    ),
  );
}

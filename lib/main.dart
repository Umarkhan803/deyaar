import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/app_repository.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final repo = AppRepository();
  final provider = AppProvider(repo);

  // Show the branded splash immediately, then load data behind it.
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const DeyaarApp(),
    ),
  );
  await provider.init();
}

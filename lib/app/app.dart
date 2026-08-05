import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class RecycleAiApp extends StatelessWidget {
  const RecycleAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GODSCAN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}

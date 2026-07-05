import 'package:flutter/material.dart';
import 'app_mode.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

class CareGridApp extends StatelessWidget {
  const CareGridApp({
    super.key,
    required this.mode,
  });

  final CareGridAppMode mode;

  @override
  Widget build(BuildContext context) {
    final routes = AppRoutes(mode: mode);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: mode.title,
      initialRoute: RouteNames.login,
      onGenerateRoute: routes.onGenerateRoute,
    );
  }
}

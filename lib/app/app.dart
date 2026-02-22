import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

class CareGridApp extends StatelessWidget {
  const CareGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareGrid',
      initialRoute: RouteNames.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

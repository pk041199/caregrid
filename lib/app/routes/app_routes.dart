import 'package:flutter/material.dart';
import '../../screens/admin_screen.dart';
import '../../screens/code_guide_screen.dart';
import '../../screens/code_master_management_screen.dart';
import '../../screens/data_collection_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case RouteNames.codeGuide:
        return MaterialPageRoute(
          builder: (_) => const CodeGuideScreen(),
          settings: settings,
        );
      case RouteNames.codeMaster:
        return MaterialPageRoute(
          builder: (_) => const CodeMasterManagementScreen(),
          settings: settings,
        );
      case RouteNames.dataCollection:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        final samplingUnit = (args['samplingUnit'] ?? '').toString();
        final setupData = (args['setupData'] as Map<String, dynamic>? ?? const {})
            .map((key, value) => MapEntry(key, value.toString()));

        return MaterialPageRoute(
          builder: (_) => DataCollectionScreen(
            samplingUnit: samplingUnit,
            setupData: setupData,
          ),
          settings: settings,
        );
      case RouteNames.admin:
        return MaterialPageRoute(
          builder: (_) => const AdminScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
          settings: settings,
        );
    }
  }
}

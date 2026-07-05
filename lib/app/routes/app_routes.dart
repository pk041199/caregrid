import 'package:flutter/material.dart';
import '../app_mode.dart';
import '../../screens/admin_screen.dart';
import '../../screens/code_guide_screen.dart';
import '../../screens/code_master_management_screen.dart';
import '../../screens/data_collection_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/field_setup_screen.dart';
import '../../screens/clinic_selection_screen.dart';
import '../../screens/clinic_dashboard_screen.dart';
import '../../screens/clinic_registration_screen.dart';
import '../../screens/clinic_forms_screen.dart';
import '../../screens/anganwadi_selection_screen.dart';
import '../../screens/anganwadi_dashboard_screen.dart';
import '../../screens/anganwadi_beneficiary_type_screen.dart';
import '../../screens/anganwadi_registration_screen.dart';
import '../../screens/anganwadi_forms_screen.dart';
import '../../screens/school_selection_screen.dart';
import '../../screens/school_dashboard_screen.dart';
import '../../screens/school_registration_screen.dart';
import '../../screens/school_forms_screen.dart';
import '../../screens/workplace_selection_screen.dart';
import '../../screens/workplace_dashboard_screen.dart';
import '../../screens/worker_registration_screen.dart';
import '../../screens/workplace_forms_screen.dart';
import '../../screens/family_registration_screen.dart';
import '../../screens/family_members_screen.dart';
import '../../screens/field_forms_screen.dart';
import '../../screens/reports_screen.dart';
import '../../screens/beneficiary_management_screen.dart';
import '../../screens/follow_up_dashboard_screen.dart';
import 'route_names.dart';

class AppRoutes {
  const AppRoutes({required this.mode});

  final CareGridAppMode mode;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => HomeScreen(appMode: mode),
          settings: settings,
        );
      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(appMode: mode),
          settings: settings,
        );

      // Field Module
      case RouteNames.fieldSetup:
        return MaterialPageRoute(
          builder: (_) => const FieldSetupScreen(),
          settings: settings,
        );

      // Clinic Module
      case RouteNames.clinicSelection:
        return MaterialPageRoute(
          builder: (_) => const ClinicSelectionScreen(),
          settings: settings,
        );

      // Anganwadi Module
      case RouteNames.anganwadiSelection:
        return MaterialPageRoute(
          builder: (_) => const AnganwadiSelectionScreen(),
          settings: settings,
        );

      // School Module
      case RouteNames.schoolSelection:
        return MaterialPageRoute(
          builder: (_) => const SchoolSelectionScreen(),
          settings: settings,
        );

      // Workplace Module
      case RouteNames.workplaceSelection:
        return MaterialPageRoute(
          builder: (_) => const WorkplaceSelectionScreen(),
          settings: settings,
        );

      case RouteNames.reports:
        return MaterialPageRoute(
          builder: (_) => const ReportsScreen(),
          settings: settings,
        );

      case RouteNames.unifiedFollowUp:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => FollowUpDashboardScreen(
            entries: (args['entries'] as List<dynamic>?)
                    ?.map((e) => Map<String, String>.from(e as Map))
                    .toList() ??
                const <Map<String, String>>[],
            samplingUnit: (args['samplingUnit'] ?? '').toString(),
            setupData: (args['setupData'] as Map<String, dynamic>? ?? const {})
                .map((key, value) => MapEntry(key.toString(), value.toString())),
            onEntriesChanged: args['onEntriesChanged'] as ValueChanged<List<Map<String, String>>>?,
            onOpenFollowUpForm: args['onOpenFollowUpForm'] as Future<bool> Function(Map<String, String>)?,
          ),
          settings: settings,
        );

      case RouteNames.beneficiaryIdentification:
        return MaterialPageRoute(
          builder: (_) => const BeneficiaryManagementScreen(mode: 'identification'),
          settings: settings,
        );
      case RouteNames.beneficiaryTimeline:
        return MaterialPageRoute(
          builder: (_) => const BeneficiaryManagementScreen(mode: 'timeline'),
          settings: settings,
        );
      case RouteNames.beneficiaryMerge:
        return MaterialPageRoute(
          builder: (_) => const BeneficiaryManagementScreen(mode: 'merge'),
          settings: settings,
        );
      case RouteNames.duplicateDetection:
        return MaterialPageRoute(
          builder: (_) => const BeneficiaryManagementScreen(mode: 'duplicates'),
          settings: settings,
        );

      // Legacy routes
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

      case RouteNames.familyRegistration:
        return MaterialPageRoute(
          builder: (_) => FamilyRegistrationScreen(
            gridId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.familyMembers:
        return MaterialPageRoute(
          builder: (_) => FamilyMembersScreen(
            familyId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.fieldForms:
        return MaterialPageRoute(
          builder: (_) => const FieldFormsScreen(),
          settings: settings,
        );
      case RouteNames.clinicDashboard:
        return MaterialPageRoute(
          builder: (_) => ClinicDashboardScreen(
            clinicId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.clinicRegistration:
        return MaterialPageRoute(
          builder: (_) => ClinicRegistrationScreen(
            clinicId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.clinicForms:
        return MaterialPageRoute(
          builder: (_) => const ClinicFormsScreen(),
          settings: settings,
        );
      case RouteNames.anganwadiDashboard:
        return MaterialPageRoute(
          builder: (_) => AnganwadiDashboardScreen(
            anganwadiId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.anganwadiBeneficiaryType:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => AnganwadiBeneficiaryTypeScreen(
            anganwadiId: (args['anganwadiId'] ?? '').toString(),
            initialType: (args['type'] ?? '').toString(),
          ),
          settings: settings,
        );
      case RouteNames.anganwadiRegistration:
        final args = (settings.arguments as Map<String, dynamic>?) ?? const {};
        return MaterialPageRoute(
          builder: (_) => AnganwadiRegistrationScreen(
            anganwadiId: (args['anganwadiId'] ?? '').toString(),
            beneficiaryType: (args['type'] ?? '').toString(),
          ),
          settings: settings,
        );
      case RouteNames.anganwadiForms:
        return MaterialPageRoute(
          builder: (_) => const AnganwadiFormsScreen(),
          settings: settings,
        );
      case RouteNames.schoolDashboard:
        return MaterialPageRoute(
          builder: (_) => SchoolDashboardScreen(
            schoolId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.studentRegistration:
        return MaterialPageRoute(
          builder: (_) => SchoolRegistrationScreen(
            schoolId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.schoolForms:
        return MaterialPageRoute(
          builder: (_) => const SchoolFormsScreen(),
          settings: settings,
        );
      case RouteNames.workplaceDashboard:
        return MaterialPageRoute(
          builder: (_) => WorkplaceDashboardScreen(
            workplaceId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.workerRegistration:
        return MaterialPageRoute(
          builder: (_) => WorkerRegistrationScreen(
            workplaceId: (settings.arguments as String?) ?? '',
          ),
          settings: settings,
        );
      case RouteNames.workplaceForms:
        return MaterialPageRoute(
          builder: (_) => const WorkplaceFormsScreen(),
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

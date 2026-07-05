import 'package:flutter/material.dart';
import '../screens/site_forms_screen.dart';

class WorkplaceFormsScreen extends StatelessWidget {
  const WorkplaceFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteFormsScreen(
      title: 'Workplace Forms',
      formOptions: [
        {
          'label': 'Occupational Health Assessment',
          'description': 'Worker risk and screening form.',
          'assetPath': 'assets/forms/ncd.json',
        },
        {
          'label': 'Follow-up Visit',
          'description': 'Worker follow-up and monitoring.',
          'assetPath': 'assets/forms/ncd_follow_up.json',
        },
      ],
    );
  }
}

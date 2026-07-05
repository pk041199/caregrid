import 'package:flutter/material.dart';
import '../screens/site_forms_screen.dart';

class SchoolFormsScreen extends StatelessWidget {
  const SchoolFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteFormsScreen(
      title: 'School Forms',
      formOptions: [
        {
          'label': 'Student Health Screening',
          'description': 'Vision, hearing, and growth monitoring.',
          'assetPath': 'assets/forms/clinical_history.json',
        },
        {
          'label': 'Follow-up Visit',
          'description': 'Next steps for student follow-up.',
          'assetPath': 'assets/forms/clinical_history_follow_up.json',
        },
      ],
    );
  }
}

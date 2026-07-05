import 'package:flutter/material.dart';
import '../screens/site_forms_screen.dart';

class FieldFormsScreen extends StatelessWidget {
  const FieldFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteFormsScreen(
      title: 'Field Forms',
      formOptions: [
        {
          'label': 'Household Health Survey',
          'description': 'Collect family and member health data.',
          'assetPath': 'assets/forms/clinical_history.json',
        },
        {
          'label': 'Follow-up Visit',
          'description': 'Capture planned and completed follow-ups.',
          'assetPath': 'assets/forms/clinical_history_follow_up.json',
        },
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../screens/site_forms_screen.dart';

class ClinicFormsScreen extends StatelessWidget {
  const ClinicFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteFormsScreen(
      title: 'Clinic Forms',
      formOptions: [
        {
          'label': 'Clinical History',
          'description': 'Primary clinical questionnaire.',
          'assetPath': 'assets/forms/clinical_history.json',
        },
        {
          'label': 'NCD Screening',
          'description': 'Non-communicable disease assessment.',
          'assetPath': 'assets/forms/ncd.json',
        },
      ],
    );
  }
}

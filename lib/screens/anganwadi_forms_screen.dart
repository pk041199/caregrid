import 'package:flutter/material.dart';
import '../screens/site_forms_screen.dart';

class AnganwadiFormsScreen extends StatelessWidget {
  const AnganwadiFormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteFormsScreen(
      title: 'Anganwadi Forms',
      formOptions: [
        {
          'label': 'Child Nutrition Check',
          'description': 'Track MUAC, weight and growth.',
          'assetPath': 'assets/forms/under_5.json',
        },
        {
          'label': 'Maternal Follow Up',
          'description': 'Follow-up for ANC/PNC visits.',
          'assetPath': 'assets/forms/anc_follow_up.json',
        },
      ],
    );
  }
}

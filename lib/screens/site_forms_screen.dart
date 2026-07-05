import 'package:flutter/material.dart';
import 'form_viewer_screen.dart';

class SiteFormsScreen extends StatelessWidget {
  const SiteFormsScreen({
    super.key,
    required this.title,
    required this.formOptions,
  });

  final String title;
  final List<Map<String, String>> formOptions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: formOptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final option = formOptions[index];
          return Card(
            child: ListTile(
              title: Text(option['label'] ?? 'Form'),
              subtitle: Text(option['description'] ?? ''),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormViewerScreen(
                      assetPath: option['assetPath']!,
                      entityLabel: option['label'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

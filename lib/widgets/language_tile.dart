import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../providers/language_provider.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isKm = lang.locale.languageCode == 'km';

    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text(context.tr('language')),
      subtitle: Text(isKm ? 'ខ្មែរ' : 'English'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    final provider = context.read<LanguageProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        Widget option(String code, String flag, String label) {
          final selected = provider.locale.languageCode == code;
          return ListTile(
            leading: Text(flag, style: const TextStyle(fontSize: 26)),
            title: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: selected
                ? Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              provider.setLanguage(code);
              Navigator.pop(sheetContext);
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('choose_language'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                option('en', '🇬🇧', 'English'),
                option('km', '🇰🇭', 'ខ្មែរ (Khmer)'),
              ],
            ),
          ),
        );
      },
    );
  }
}
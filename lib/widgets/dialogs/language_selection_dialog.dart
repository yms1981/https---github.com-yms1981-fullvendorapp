import 'package:FullVendor/model/login_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> selectLanguage({
  required BuildContext context,
}) async {
  await showDialog(
    context: context,
    builder: (context) => const AlertDialog(content: LanguageSelectionWidget()),
  );
}

class LanguageSelectionWidget extends StatefulWidget {
  const LanguageSelectionWidget({super.key});

  @override
  State<LanguageSelectionWidget> createState() =>
      _LanguageSelectionWidgetState();
}

class _LanguageSelectionWidgetState extends State<LanguageSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('select_language'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('English'),
            leading: const Text('EN'),
            onTap: () {
              Locale newLocale = const Locale('en', 'US');
              // apply to full app
              LoginDataModel instance = LoginDataModel.instance;
              instance.info?.languageId = '1';
              instance.save();

              context.setLocale(newLocale);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            title: const Text('Spanish'),
            leading: const Text('ES'),
            onTap: () {
              // set Spanish to full app
              Locale newLocale = const Locale('es', 'ES');
              // apply to full app
              LoginDataModel instance = LoginDataModel.instance;
              instance.info?.languageId = '2';
              instance.save();

              context.setLocale(newLocale);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

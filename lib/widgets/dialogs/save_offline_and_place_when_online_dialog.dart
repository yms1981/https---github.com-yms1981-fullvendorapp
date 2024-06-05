import 'package:FullVendor/application/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<bool> confirmSaveOfflineAndPlaceWhenNetworkAvailable({
  required BuildContext context,
}) async {
  bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return const SaveOfflineConfirmationWidget();
    },
  );
  return result ?? false;
}

class SaveOfflineConfirmationWidget extends StatelessWidget {
  const SaveOfflineConfirmationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('network_issue')),
      content: Text(tr('save_and_place_when_online')),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.black,
      ),
      actions: <Widget>[
        TextButton(
          child: Text(tr('cancel')),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        MaterialButton(
          textColor: Colors.white,
          color: appPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(tr('save')),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}

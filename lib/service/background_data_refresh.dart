import 'package:workmanager/workmanager.dart';

import '../db/synced_db.dart';

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  print("backgroundCallbackDispatcher");
  Workmanager().executeTask((task, inputData) async {
    if (task == "startMicroUpdate") {
      await startMicroUpdates();
      await Future.delayed(const Duration(seconds: 5));
    }
    return Future.value(true);
  });
}

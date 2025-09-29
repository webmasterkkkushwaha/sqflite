import 'dart:io';

import 'package:process_run/shell.dart';

Future<void> main() async {
  await createProjectAndroidJava();
}

Future<void> createProjectAndroidJava() async {
  try {
    await Directory('android').delete(recursive: true);
  } catch (_) {}

  final shell = Shell();
  await shell.run(
    'flutter create --platforms android --android-language java .',
  );
}

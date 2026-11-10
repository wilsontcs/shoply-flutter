import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shoply_flutter/root_app.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const RootApp());
    },
    (Object error, StackTrace stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Shoply',
        ),
      );
    },
  );
}

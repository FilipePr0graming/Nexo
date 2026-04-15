import 'package:flutter/material.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  final services = await AppBootstrap.initialize();
  runApp(NexoApp(services: services));
}

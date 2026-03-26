import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:servisku/app.dart';
import 'package:servisku/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  runApp(const ProviderScope(child: App()));
}

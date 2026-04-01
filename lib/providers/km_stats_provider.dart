import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/providers/fuel_record_provider.dart';
import 'package:servisku/providers/service_record_provider.dart';
import 'package:servisku/utils/service_calculator.dart';

final kmStatsProvider = FutureProvider.family<KmStats?, int>((ref, vehicleId) async {
  // Watch kedua provider supaya otomatis recompute saat data berubah
  ref.watch(serviceRecordProvider);
  ref.watch(fuelRecordsByVehicleProvider(vehicleId));

  final points = await DatabaseHelper.instance.getKmHistory(vehicleId);
  return ServiceCalculator.calculateKmStats(points);
});

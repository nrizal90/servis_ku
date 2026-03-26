import 'package:go_router/go_router.dart';
import 'package:servisku/models/fuel_record.dart';
import 'package:servisku/models/service_record.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/screens/home/home_screen.dart';
import 'package:servisku/screens/vehicle/add_vehicle_screen.dart';
import 'package:servisku/screens/vehicle/vehicle_detail_screen.dart';
import 'package:servisku/screens/service/add_service_screen.dart';
import 'package:servisku/screens/fuel/add_fuel_screen.dart';
import 'package:servisku/services/notification_service.dart';

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-vehicle',
      builder: (context, state) => const AddVehicleScreen(),
    ),
    GoRoute(
      path: '/edit-vehicle',
      builder: (context, state) =>
          AddVehicleScreen(existingVehicle: state.extra as Vehicle),
    ),
    GoRoute(
      path: '/vehicle/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return VehicleDetailScreen(vehicleId: id);
      },
    ),
    GoRoute(
      path: '/vehicle/:id/service',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddServiceScreen(vehicleId: id);
      },
    ),
    GoRoute(
      path: '/vehicle/:id/service/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddServiceScreen(
          vehicleId: id,
          existingRecord: state.extra as ServiceRecord,
        );
      },
    ),
    GoRoute(
      path: '/vehicle/:id/fuel',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddFuelScreen(vehicleId: id);
      },
    ),
    GoRoute(
      path: '/vehicle/:id/fuel/edit',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return AddFuelScreen(
          vehicleId: id,
          existingRecord: state.extra as FuelRecord,
        );
      },
    ),
  ],
);

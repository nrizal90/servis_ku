import 'package:go_router/go_router.dart';
import 'package:servisku/screens/home/home_screen.dart';
import 'package:servisku/screens/vehicle/add_vehicle_screen.dart';
import 'package:servisku/screens/vehicle/vehicle_detail_screen.dart';
import 'package:servisku/screens/service/add_service_screen.dart';

final appRouter = GoRouter(
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
  ],
);

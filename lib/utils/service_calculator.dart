import 'package:servisku/models/service_record.dart';
import 'package:servisku/models/service_type.dart';
import 'package:servisku/models/vehicle.dart';

class ServiceStatus {
  final String status; // 'ok' | 'soon' | 'overdue' | 'unknown'
  final int? daysLeft;
  final int? kmLeft;

  const ServiceStatus({required this.status, this.daysLeft, this.kmLeft});

  static const ServiceStatus unknown =
      ServiceStatus(status: 'unknown');

  bool get isOverdue => status == 'overdue';
  bool get isSoon => status == 'soon';
  bool get isOk => status == 'ok';
  bool get isUnknown => status == 'unknown';
}

class UpcomingAlert {
  final Vehicle vehicle;
  final String type; // 'service' | 'stnk' | 'plat'
  final String label;
  final String icon;
  final ServiceStatus status;

  const UpcomingAlert({
    required this.vehicle,
    required this.type,
    required this.label,
    required this.icon,
    required this.status,
  });
}

class ServiceCalculator {
  static ServiceStatus getStatus(
      ServiceRecord? lastRecord, ServiceType type) {
    if (lastRecord == null) return ServiceStatus.unknown;

    final now = DateTime.now();
    final daysSince = now.difference(lastRecord.date).inDays;

    String status = 'ok';
    int? daysLeft;
    int? kmLeft;

    if (type.intervalDays != null) {
      daysLeft = type.intervalDays! - daysSince;
      if (daysLeft < 0) {
        status = 'overdue';
      } else if (daysLeft <= 14) {
        status = 'soon';
      }
    }

    if (type.intervalKm != null && lastRecord.km != null) {
      kmLeft = type.intervalKm! - (lastRecord.km! - lastRecord.km!);
    }

    return ServiceStatus(status: status, daysLeft: daysLeft, kmLeft: kmLeft);
  }

  static ServiceStatus getStnkStatus(DateTime? stnkDueDate) {
    if (stnkDueDate == null) return ServiceStatus.unknown;
    final daysLeft = stnkDueDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return ServiceStatus(status: 'overdue', daysLeft: daysLeft);
    if (daysLeft <= 30) return ServiceStatus(status: 'soon', daysLeft: daysLeft);
    return ServiceStatus(status: 'ok', daysLeft: daysLeft);
  }

  static ServiceStatus getPlatStatus(DateTime? platDueDate) {
    if (platDueDate == null) return ServiceStatus.unknown;
    final daysLeft = platDueDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return ServiceStatus(status: 'overdue', daysLeft: daysLeft);
    if (daysLeft <= 60) return ServiceStatus(status: 'soon', daysLeft: daysLeft);
    return ServiceStatus(status: 'ok', daysLeft: daysLeft);
  }

  static List<UpcomingAlert> getAllAlerts(
    List<Vehicle> vehicles,
    List<ServiceRecord> allRecords,
  ) {
    final alerts = <UpcomingAlert>[];

    for (final vehicle in vehicles) {
      final vehicleRecords =
          allRecords.where((r) => r.vehicleId == vehicle.id).toList();

      final serviceTypes = getServiceTypesFor(vehicle.vehicleType);
      for (final st in serviceTypes) {
        ServiceRecord? last;
        try {
          last = vehicleRecords
              .where((r) => r.serviceType == st.id)
              .reduce((a, b) => a.date.isAfter(b.date) ? a : b);
        } catch (_) {
          last = null;
        }

        final status = getStatus(last, st);
        if (status.isOverdue || status.isSoon) {
          alerts.add(UpcomingAlert(
            vehicle: vehicle,
            type: 'service',
            label: st.label,
            icon: st.icon,
            status: status,
          ));
        }
      }

      final stnkStatus = getStnkStatus(vehicle.stnkDueDate);
      if (stnkStatus.isOverdue || stnkStatus.isSoon) {
        alerts.add(UpcomingAlert(
          vehicle: vehicle,
          type: 'stnk',
          label: 'Pajak STNK',
          icon: '📋',
          status: stnkStatus,
        ));
      }

      final platStatus = getPlatStatus(vehicle.platDueDate);
      if (platStatus.isOverdue || platStatus.isSoon) {
        alerts.add(UpcomingAlert(
          vehicle: vehicle,
          type: 'plat',
          label: 'Ganti Plat',
          icon: '🔖',
          status: platStatus,
        ));
      }
    }

    alerts.sort(
        (a, b) => (a.status.daysLeft ?? 0).compareTo(b.status.daysLeft ?? 0));
    return alerts;
  }
}

import 'package:flutter/material.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/models/service_record.dart';
import 'package:servisku/models/service_type.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/utils/service_calculator.dart';

class ServiceStatusGrid extends StatelessWidget {
  final Vehicle vehicle;
  final List<ServiceRecord> records;

  const ServiceStatusGrid({
    super.key,
    required this.vehicle,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final types = getServiceTypesFor(vehicle.vehicleType);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: types.length,
      itemBuilder: (ctx, i) {
        final st = types[i];
        ServiceRecord? last;
        try {
          last = records
              .where((r) => r.serviceType == st.id)
              .reduce((a, b) => a.date.isAfter(b.date) ? a : b);
        } catch (_) {
          last = null;
        }
        final status = ServiceCalculator.getStatus(last, st);
        return _ServiceCell(serviceType: st, status: status);
      },
    );
  }
}

class _ServiceCell extends StatelessWidget {
  final ServiceType serviceType;
  final ServiceStatus status;

  const _ServiceCell({required this.serviceType, required this.status});

  Color get _color {
    if (status.isUnknown) return AppColors.textHint;
    if (status.isOverdue) return AppColors.danger;
    if (status.isSoon) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(serviceType.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            serviceType.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/models/service_record.dart';
import 'package:servisku/models/service_type.dart';
import 'package:servisku/utils/format_utils.dart';

class HistoryList extends StatelessWidget {
  final List<ServiceRecord> records;
  final void Function(ServiceRecord)? onDelete;
  final void Function(ServiceRecord)? onEdit;

  const HistoryList({super.key, required this.records, this.onDelete, this.onEdit});

  String _icon(String serviceTypeId) {
    try {
      return defaultServiceTypes
          .firstWhere((st) => st.id == serviceTypeId)
          .icon;
    } catch (_) {
      return '🔧';
    }
  }

  String _label(String serviceTypeId) {
    try {
      return defaultServiceTypes
          .firstWhere((st) => st.id == serviceTypeId)
          .label;
    } catch (_) {
      return serviceTypeId;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Belum ada riwayat service.',
            style: TextStyle(color: AppColors.textHint),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final r = records[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: Text(_icon(r.serviceType),
              style: const TextStyle(fontSize: 24)),
          title: Text(
            _label(r.serviceType),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            [
              formatDate(r.date),
              if (r.km != null) formatKm(r.km!),
              if (r.bengkel != null) r.bengkel!,
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.cost != null)
                Text(
                  formatCurrency(r.cost!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              if (onEdit != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textHint),
                  onPressed: () => onEdit!(r),
                ),
              ],
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.textHint),
                  onPressed: () => onDelete!(r),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

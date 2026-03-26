import 'package:flutter/material.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/models/service_type.dart';
import 'package:servisku/models/vehicle.dart';

class ServiceTypeSelector extends StatelessWidget {
  final VehicleType vehicleType;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const ServiceTypeSelector({
    super.key,
    required this.vehicleType,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final types = getServiceTypesFor(vehicleType);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: types.length,
      itemBuilder: (ctx, i) {
        final st = types[i];
        final selected = selectedId == st.id;
        return GestureDetector(
          onTap: () => onSelected(st.id),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(st.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  st.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

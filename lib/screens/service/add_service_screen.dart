import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:servisku/config/theme.dart';
import 'package:servisku/database/database_helper.dart';
import 'package:servisku/models/service_record.dart';
import 'package:servisku/models/service_type.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/providers/service_record_provider.dart';
import 'package:servisku/screens/service/widgets/service_type_selector.dart';
import 'package:servisku/services/notification_service.dart';
import 'package:servisku/utils/format_utils.dart';
import 'package:servisku/widgets/app_button.dart';
import 'package:servisku/widgets/app_input.dart';
import 'package:servisku/widgets/toast.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  final int vehicleId;
  final ServiceRecord? existingRecord;

  const AddServiceScreen({
    super.key,
    required this.vehicleId,
    this.existingRecord,
  });

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _kmCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _bengkelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Vehicle? _vehicle;
  late String? _selectedTypeId;
  late DateTime _date;
  bool _saving = false;

  bool get _isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecord;
    _selectedTypeId = r?.serviceType;
    _date = r?.date ?? DateTime.now();
    _kmCtrl.text = r?.km?.toString() ?? '';
    _costCtrl.text = r?.cost?.toString() ?? '';
    _bengkelCtrl.text = r?.bengkel ?? '';
    _notesCtrl.text = r?.notes ?? '';

    DatabaseHelper.instance
        .getVehicleById(widget.vehicleId)
        .then((v) => setState(() => _vehicle = v));
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _costCtrl.dispose();
    _bengkelCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_selectedTypeId == null) {
      showToast(context, 'Pilih jenis service dulu', isError: true);
      return;
    }
    setState(() => _saving = true);

    try {
      ServiceRecord saved;

      if (_isEdit) {
        final updated = widget.existingRecord!.copyWith(
          serviceType: _selectedTypeId,
          date: _date,
          km: _kmCtrl.text.isNotEmpty ? int.tryParse(_kmCtrl.text) : null,
          cost: _costCtrl.text.isNotEmpty ? int.tryParse(_costCtrl.text) : null,
          bengkel: _bengkelCtrl.text.trim().isNotEmpty
              ? _bengkelCtrl.text.trim()
              : null,
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
        );
        await ref.read(serviceRecordProvider.notifier).updateRecord(updated);
        saved = updated;
      } else {
        final record = ServiceRecord(
          vehicleId: widget.vehicleId,
          serviceType: _selectedTypeId!,
          date: _date,
          km: _kmCtrl.text.isNotEmpty ? int.tryParse(_kmCtrl.text) : null,
          cost: _costCtrl.text.isNotEmpty ? int.tryParse(_costCtrl.text) : null,
          bengkel: _bengkelCtrl.text.trim().isNotEmpty
              ? _bengkelCtrl.text.trim()
              : null,
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
          createdAt: DateTime.now(),
        );
        saved = await ref.read(serviceRecordProvider.notifier).addRecord(record);
      }

      // Reschedule notifikasi untuk service type ini
      if (_vehicle != null) {
        final st = defaultServiceTypes
            .where((s) => s.id == saved.serviceType)
            .firstOrNull;
        if (st != null && st.intervalDays != null) {
          await NotificationService.instance
              .cancelServiceReminders(_vehicle!, st);
          await NotificationService.instance
              .scheduleServiceReminders(_vehicle!, st, saved);
        }
      }

      if (mounted) {
        showToast(context,
            _isEdit ? 'Service berhasil diupdate!' : 'Service berhasil dicatat!');
        context.pop();
      }
    } catch (e) {
      if (mounted) showToast(context, 'Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vehicle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit Service' : 'Catat Service')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Text(_vehicle!.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _vehicle!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _vehicle!.plate,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Jenis Service *',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          ServiceTypeSelector(
            vehicleType: _vehicle!.vehicleType,
            selectedId: _selectedTypeId,
            onSelected: (id) => setState(() => _selectedTypeId = id),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Service',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        formatDate(_date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  label: 'Kilometer',
                  hint: 'cth: 15000',
                  controller: _kmCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInput(
                  label: 'Biaya (Rp)',
                  hint: 'cth: 85000',
                  controller: _costCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppInput(
            label: 'Nama Bengkel',
            hint: 'cth: Bengkel Jaya Motor',
            controller: _bengkelCtrl,
          ),
          const SizedBox(height: 14),
          AppInput(
            label: 'Catatan',
            hint: 'Catatan tambahan...',
            controller: _notesCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 30),
          AppButton(
            label: _isEdit ? 'Update' : 'Simpan',
            onPressed: _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:servisku/models/service_record.dart';
import 'package:servisku/models/service_type.dart';
import 'package:servisku/models/vehicle.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _createChannels();
  }

  Future<void> _createChannels() async {
    const serviceChannel = AndroidNotificationChannel(
      'service_reminder',
      'Pengingat Service',
      description: 'Notifikasi jadwal service berkala kendaraan',
      importance: Importance.high,
    );
    const stnkChannel = AndroidNotificationChannel(
      'stnk_reminder',
      'Pengingat Pajak STNK',
      description: 'Notifikasi jatuh tempo pajak STNK tahunan',
      importance: Importance.high,
    );
    const platChannel = AndroidNotificationChannel(
      'plat_reminder',
      'Pengingat Ganti Plat',
      description: 'Notifikasi jatuh tempo ganti plat 5 tahunan',
      importance: Importance.high,
    );
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(serviceChannel);
    await androidPlugin?.createNotificationChannel(stnkChannel);
    await androidPlugin?.createNotificationChannel(platChannel);
  }

  void _onTap(NotificationResponse response) {
    // payload format: "vehicleId"
    // Navigasi ditangani di main.dart via navigatorKey
    if (response.payload != null) {
      navigatorKey.currentState
          ?.pushNamed('/vehicle/${response.payload}');
    }
  }

  /// Request permission (Android 13+)
  Future<bool> requestPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  // ─── Service Berkala ──────────────────────────────────────────────────────

  Future<void> scheduleServiceReminders(
    Vehicle vehicle,
    ServiceType serviceType,
    ServiceRecord lastRecord,
  ) async {
    if (serviceType.intervalDays == null) return;

    final typeIndex = defaultServiceTypes.indexOf(serviceType);
    final dueDate = lastRecord.date.add(Duration(days: serviceType.intervalDays!));

    final h7Date = dueDate.subtract(const Duration(days: 7));
    final h0Date = dueDate;

    final idH7 = vehicle.id! * 1000 + typeIndex * 2;
    final idH0 = vehicle.id! * 1000 + typeIndex * 2 + 1;

    await _cancelById(idH7);
    await _cancelById(idH0);

    final now = DateTime.now();

    if (h7Date.isAfter(now)) {
      await _scheduleNotif(
        id: idH7,
        title: '⚠️ Service ${serviceType.label}',
        body: '${vehicle.name} (${vehicle.plate}) — dalam 7 hari',
        scheduledDate: h7Date,
        channelId: 'service_reminder',
        payload: '${vehicle.id}',
      );
    }

    if (h0Date.isAfter(now)) {
      await _scheduleNotif(
        id: idH0,
        title: '🔴 Waktunya service ${serviceType.label}!',
        body: '${vehicle.name} (${vehicle.plate}) sudah jatuh tempo',
        scheduledDate: h0Date,
        channelId: 'service_reminder',
        payload: '${vehicle.id}',
      );
    }
  }

  Future<void> cancelServiceReminders(Vehicle vehicle, ServiceType serviceType) async {
    final typeIndex = defaultServiceTypes.indexOf(serviceType);
    await _cancelById(vehicle.id! * 1000 + typeIndex * 2);
    await _cancelById(vehicle.id! * 1000 + typeIndex * 2 + 1);
  }

  // ─── STNK ─────────────────────────────────────────────────────────────────

  Future<void> scheduleStnkReminders(Vehicle vehicle) async {
    final due = vehicle.stnkDueDate;
    if (due == null) return;

    final base = vehicle.id! * 1000 + 900;
    await _cancelById(base);
    await _cancelById(base + 1);
    await _cancelById(base + 2);

    final now = DateTime.now();
    final h30 = due.subtract(const Duration(days: 30));
    final h7 = due.subtract(const Duration(days: 7));

    if (h30.isAfter(now)) {
      await _scheduleNotif(
        id: base,
        title: '📋 Pajak STNK ${vehicle.name}',
        body: 'Jatuh tempo dalam 30 hari',
        scheduledDate: h30,
        channelId: 'stnk_reminder',
        payload: '${vehicle.id}',
      );
    }
    if (h7.isAfter(now)) {
      await _scheduleNotif(
        id: base + 1,
        title: '⚠️ Pajak STNK ${vehicle.name}',
        body: 'Jatuh tempo dalam 7 hari!',
        scheduledDate: h7,
        channelId: 'stnk_reminder',
        payload: '${vehicle.id}',
      );
    }
    if (due.isAfter(now)) {
      await _scheduleNotif(
        id: base + 2,
        title: '🔴 Pajak STNK ${vehicle.name}',
        body: 'Jatuh tempo HARI INI!',
        scheduledDate: due,
        channelId: 'stnk_reminder',
        payload: '${vehicle.id}',
      );
    }
  }

  Future<void> cancelStnkReminders(Vehicle vehicle) async {
    final base = vehicle.id! * 1000 + 900;
    for (var i = 0; i < 3; i++) { await _cancelById(base + i); }
  }

  // ─── Ganti Plat ───────────────────────────────────────────────────────────

  Future<void> schedulePlatReminders(Vehicle vehicle) async {
    final due = vehicle.platDueDate;
    if (due == null) return;

    final base = vehicle.id! * 1000 + 950;
    await _cancelById(base);
    await _cancelById(base + 1);
    await _cancelById(base + 2);

    final now = DateTime.now();
    final h60 = due.subtract(const Duration(days: 60));
    final h30 = due.subtract(const Duration(days: 30));

    if (h60.isAfter(now)) {
      await _scheduleNotif(
        id: base,
        title: '🔖 Ganti Plat ${vehicle.name}',
        body: 'Jatuh tempo dalam 60 hari',
        scheduledDate: h60,
        channelId: 'plat_reminder',
        payload: '${vehicle.id}',
      );
    }
    if (h30.isAfter(now)) {
      await _scheduleNotif(
        id: base + 1,
        title: '⚠️ Ganti Plat ${vehicle.name}',
        body: 'Jatuh tempo dalam 30 hari!',
        scheduledDate: h30,
        channelId: 'plat_reminder',
        payload: '${vehicle.id}',
      );
    }
    if (due.isAfter(now)) {
      await _scheduleNotif(
        id: base + 2,
        title: '🔴 Ganti Plat ${vehicle.name}',
        body: 'Jatuh tempo HARI INI!',
        scheduledDate: due,
        channelId: 'plat_reminder',
        payload: '${vehicle.id}',
      );
    }
  }

  Future<void> cancelPlatReminders(Vehicle vehicle) async {
    final base = vehicle.id! * 1000 + 950;
    for (var i = 0; i < 3; i++) { await _cancelById(base + i); }
  }

  // ─── Reschedule semua untuk semua kendaraan ───────────────────────────────

  Future<void> rescheduleAll(
    List<Vehicle> vehicles,
    List<ServiceRecord> allRecords,
  ) async {
    for (final vehicle in vehicles) {
      await scheduleStnkReminders(vehicle);
      await schedulePlatReminders(vehicle);

      final serviceTypes = getServiceTypesFor(vehicle.vehicleType);
      for (final st in serviceTypes) {
        if (st.intervalDays == null) continue;
        final vehicleRecords = allRecords.where((r) => r.vehicleId == vehicle.id);
        ServiceRecord? last;
        try {
          last = vehicleRecords
              .where((r) => r.serviceType == st.id)
              .reduce((a, b) => a.date.isAfter(b.date) ? a : b);
        } catch (_) {
          continue;
        }
        await scheduleServiceReminders(vehicle, st, last);
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _scheduleNotif({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    String? payload,
  }) async {
    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      // Lewati jika gagal schedule (e.g., permission belum granted)
    }
  }

  Future<void> _cancelById(int id) async {
    await _plugin.cancel(id);
  }
}

/// GlobalKey untuk navigasi dari notification tap
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

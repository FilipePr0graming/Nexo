import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/nexo_table_service.dart';
import '../../../core/storage/local_json_store.dart';
import '../../../core/utils/id_generator.dart';
import '../models/reminder_model.dart';
import 'local_reminder_notifications.dart';

class RemindersService extends ChangeNotifier {
  RemindersService({
    required SupabaseClient? client,
    required LocalJsonStore localStore,
  }) : _store = NexoTableService<ReminderModel>(
          client: client,
          localStore: localStore,
          table: 'reminders',
          storageKey: 'nexo.cache.reminders',
          fromJson: ReminderModel.fromJson,
          toJson: (reminder) => reminder.toJson(),
          idOf: (reminder) => reminder.id,
          orderBy: 'due_date',
          ascending: true,
          syncErrorMessage: 'Nao foi possivel sincronizar lembretes agora.',
          sort: (left, right) => left.dueDate.compareTo(right.dueDate),
        ) {
    _store.addListener(notifyListeners);
  }

  final NexoTableService<ReminderModel> _store;
  final LocalReminderNotifications _notifications =
      LocalReminderNotifications();

  List<ReminderModel> get reminders => _store.items;
  bool get isLoading => _store.isLoading;
  bool get isSyncing => _store.isSyncing;
  String? get errorMessage => _store.errorMessage;

  Future<void> initialize() async {
    await Future.wait<void>([
      _store.initialize(),
      _notifications.initialize(),
    ]);
    await _scheduleOpenReminders();
  }

  Future<void> refresh() async {
    await _store.refresh();
    await _scheduleOpenReminders();
  }

  Future<void> createReminder({
    required String title,
    String? description,
    required DateTime dueDate,
    String? recurrence,
    String? relatedTable,
    String? relatedId,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final reminder = ReminderModel(
      id: IdGenerator.next('reminder'),
      title: title.trim(),
      description: _emptyToNull(description),
      dueDate: dueDate.toUtc(),
      status: ReminderStatus.open,
      recurrence: _emptyToNull(recurrence),
      relatedTable: _emptyToNull(relatedTable),
      relatedId: _emptyToNull(relatedId),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await _store.upsertItem(reminder);
    await _notifications.schedule(reminder);
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    final updated = reminder.copyWith(updatedAt: DateTime.now().toUtc());
    await _store.upsertItem(updated);
    if (updated.status == ReminderStatus.open) {
      await _notifications.schedule(updated);
    } else {
      await _notifications.cancel(updated.id);
    }
  }

  Future<void> markDone(String id) async {
    final reminder = reminders.cast<ReminderModel?>().firstWhere(
          (item) => item?.id == id,
          orElse: () => null,
        );
    if (reminder == null) {
      return Future<void>.value();
    }
    await updateReminder(reminder.copyWith(status: ReminderStatus.done));
    await _notifications.cancel(id);
  }

  Future<void> deleteReminder(String id) async {
    await _store.deleteById(id);
    await _notifications.cancel(id);
  }

  Future<void> _scheduleOpenReminders() async {
    for (final reminder in reminders.where(
      (item) => item.status == ReminderStatus.open,
    )) {
      await _notifications.schedule(reminder);
    }
  }

  @override
  void dispose() {
    _store
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

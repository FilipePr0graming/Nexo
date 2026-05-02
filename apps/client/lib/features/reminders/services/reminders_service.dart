import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/nexo_table_service.dart';
import '../../../core/storage/local_json_store.dart';
import '../../../core/utils/id_generator.dart';
import '../models/reminder_model.dart';

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

  List<ReminderModel> get reminders => _store.items;
  bool get isLoading => _store.isLoading;
  bool get isSyncing => _store.isSyncing;
  String? get errorMessage => _store.errorMessage;

  Future<void> initialize() => _store.initialize();
  Future<void> refresh() => _store.refresh();

  Future<void> createReminder({
    required String title,
    String? description,
    required DateTime dueDate,
    String? recurrence,
    String? relatedTable,
    String? relatedId,
  }) {
    final timestamp = DateTime.now().toUtc();
    return _store.upsertItem(
      ReminderModel(
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
      ),
    );
  }

  Future<void> updateReminder(ReminderModel reminder) {
    return _store.upsertItem(
      reminder.copyWith(updatedAt: DateTime.now().toUtc()),
    );
  }

  Future<void> markDone(String id) {
    final reminder = reminders.cast<ReminderModel?>().firstWhere(
          (item) => item?.id == id,
          orElse: () => null,
        );
    if (reminder == null) {
      return Future<void>.value();
    }
    return updateReminder(reminder.copyWith(status: ReminderStatus.done));
  }

  Future<void> deleteReminder(String id) => _store.deleteById(id);

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

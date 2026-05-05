import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/nexo_table_service.dart';
import '../../../core/storage/local_json_store.dart';
import '../../../core/utils/id_generator.dart';
import '../../../core/utils/production_data_guard.dart';
import '../models/goal_model.dart';

class GoalsService extends ChangeNotifier {
  GoalsService({
    required SupabaseClient? client,
    required LocalJsonStore localStore,
  }) : _store = NexoTableService<GoalModel>(
          client: client,
          localStore: localStore,
          table: 'goals',
          storageKey: 'nexo.cache.goals',
          fromJson: GoalModel.fromJson,
          toJson: (goal) => goal.toJson(),
          idOf: (goal) => goal.id,
          syncErrorMessage: 'Nao foi possivel sincronizar metas agora.',
          sort: (left, right) => right.updatedAt.compareTo(left.updatedAt),
        ) {
    _store.addListener(notifyListeners);
  }

  final NexoTableService<GoalModel> _store;

  List<GoalModel> get goals => _store.items
      .where((goal) => ProductionDataGuard.visible([goal.title]))
      .toList(growable: false);
  bool get isLoading => _store.isLoading;
  bool get isSyncing => _store.isSyncing;
  String? get errorMessage => _store.errorMessage;

  Future<void> initialize() => _store.initialize();
  Future<void> refresh() => _store.refresh();

  Future<void> createGoal({
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? dueDate,
  }) {
    final timestamp = DateTime.now().toUtc();
    return _store.upsertItem(
      GoalModel(
        id: IdGenerator.next('goal'),
        title: title.trim(),
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        dueDate: dueDate?.toUtc(),
        status: GoalStatus.active,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  Future<void> updateGoal(GoalModel goal) {
    return _store.upsertItem(goal.copyWith(updatedAt: DateTime.now().toUtc()));
  }

  Future<void> deleteGoal(String id) => _store.deleteById(id);

  @override
  void dispose() {
    _store
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}

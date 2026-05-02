import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/nexo_table_service.dart';
import '../../../core/storage/local_json_store.dart';
import '../../../core/utils/id_generator.dart';
import '../models/project_model.dart';

class ProjectsService extends ChangeNotifier {
  ProjectsService({
    required SupabaseClient? client,
    required LocalJsonStore localStore,
  }) : _store = NexoTableService<ProjectModel>(
          client: client,
          localStore: localStore,
          table: 'projects',
          storageKey: 'nexo.cache.projects',
          fromJson: ProjectModel.fromJson,
          toJson: (project) => project.toJson(),
          idOf: (project) => project.id,
          syncErrorMessage: 'Nao foi possivel sincronizar projetos agora.',
          sort: (left, right) => right.updatedAt.compareTo(left.updatedAt),
        ) {
    _store.addListener(notifyListeners);
  }

  final NexoTableService<ProjectModel> _store;

  List<ProjectModel> get projects => _store.items;
  bool get isLoading => _store.isLoading;
  bool get isSyncing => _store.isSyncing;
  String? get errorMessage => _store.errorMessage;

  Future<void> initialize() => _store.initialize();
  Future<void> refresh() => _store.refresh();

  Future<void> createProject({
    String? clientId,
    required String name,
    String stage = 'briefing',
    ProjectStatus status = ProjectStatus.active,
    double budgetAmount = 0,
    DateTime? dueDate,
    String? notes,
  }) {
    final timestamp = DateTime.now().toUtc();
    return _store.upsertItem(
      ProjectModel(
        id: IdGenerator.next('project'),
        clientId: _emptyToNull(clientId),
        name: name.trim(),
        stage: stage.trim().isEmpty ? 'briefing' : stage.trim(),
        status: status,
        budgetAmount: budgetAmount,
        dueDate: dueDate?.toUtc(),
        notes: _emptyToNull(notes),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  Future<void> updateProject(ProjectModel project) {
    return _store.upsertItem(
      project.copyWith(updatedAt: DateTime.now().toUtc()),
    );
  }

  Future<void> deleteProject(String id) => _store.deleteById(id);

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

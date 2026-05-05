import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/nexo_table_service.dart';
import '../../../core/storage/local_json_store.dart';
import '../../../core/utils/id_generator.dart';
import '../models/note_model.dart';
import '../models/note_details.dart';

class NotesService extends ChangeNotifier {
  NotesService({
    required SupabaseClient? client,
    required LocalJsonStore localStore,
  }) : _store = NexoTableService<NoteModel>(
          client: client,
          localStore: localStore,
          table: 'notes',
          storageKey: 'nexo.cache.notes',
          fromJson: NoteModel.fromJson,
          toJson: (note) => note.toJson(),
          idOf: (note) => note.id,
          syncErrorMessage: 'Nao foi possivel sincronizar anotacoes agora.',
          sort: (left, right) => right.updatedAt.compareTo(left.updatedAt),
        ) {
    _store.addListener(notifyListeners);
  }

  final NexoTableService<NoteModel> _store;

  List<NoteModel> get notes => _store.items;
  bool get isLoading => _store.isLoading;
  bool get isSyncing => _store.isSyncing;
  String? get errorMessage => _store.errorMessage;

  Future<void> initialize() => _store.initialize();
  Future<void> refresh() => _store.refresh();

  Future<void> createNote({
    required String title,
    required String body,
    String? category,
    String priority = 'normal',
    DateTime? reminderAt,
    bool isImportant = false,
    bool isPinned = false,
    String? relatedTable,
    String? relatedId,
  }) {
    final timestamp = DateTime.now().toUtc();
    return _store.upsertItem(
      NoteModel(
        id: IdGenerator.next('note'),
        title: title.trim().isEmpty ? 'Sem titulo' : title.trim(),
        body: NoteDetails(
          content: body.trim(),
          category: _emptyToNull(category),
          priority: priority,
          reminderAt: reminderAt?.toUtc(),
          isImportant: isImportant,
          isPinned: isPinned,
        ).encode(),
        relatedTable: _emptyToNull(relatedTable),
        relatedId: _emptyToNull(relatedId),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  Future<void> updateNote(NoteModel note) {
    return _store.upsertItem(note.copyWith(updatedAt: DateTime.now().toUtc()));
  }

  Future<void> updateNoteDetails(
    NoteModel note,
    NoteDetails details, {
    String? title,
  }) {
    return updateNote(
      note.copyWith(
        title: title ?? note.title,
        body: details.encode(),
      ),
    );
  }

  Future<void> deleteNote(String id) => _store.deleteById(id);

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

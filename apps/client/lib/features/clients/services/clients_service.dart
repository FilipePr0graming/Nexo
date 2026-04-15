import 'package:flutter/foundation.dart';

import '../../../core/utils/id_generator.dart';
import '../data/repositories/clients_repository.dart';
import '../models/client_model.dart';

class ClientsService extends ChangeNotifier {
  ClientsService(this._repository);

  final ClientsRepository _repository;

  List<ClientModel> _clients = const [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _initialized = false;
  String? _errorMessage;

  List<ClientModel> get clients => _clients;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get isReady => _initialized;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _isLoading = true;
    notifyListeners();

    _clients = await _repository.loadLocal();
    _isLoading = false;
    notifyListeners();

    await refresh();
  }

  Future<void> refresh() async {
    if (_isSyncing || !_repository.isRemoteEnabled) {
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _clients = await _repository.refreshFromRemote();
    } catch (_) {
      _errorMessage = 'Nao foi possivel atualizar clientes agora.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> createClient({
    required String name,
    required ClientType clientType,
    String? legalName,
    String? document,
    String? phone,
    String? notes,
    String? origin,
    String? zipCode,
    String? street,
    String? streetNumber,
    String? addressComplement,
    String? neighborhood,
    String? city,
    String? stateCode,
    String? country,
    required ClientStatus status,
    required ClientBillingType billingType,
    required bool hasDanielParticipation,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final client = ClientModel(
      id: IdGenerator.next('client'),
      name: name.trim(),
      clientType: clientType,
      legalName: _emptyToNull(legalName),
      document: _emptyToNull(document),
      phone: _emptyToNull(phone),
      notes: _emptyToNull(notes),
      origin: _emptyToNull(origin),
      zipCode: _emptyToNull(zipCode),
      street: _emptyToNull(street),
      streetNumber: _emptyToNull(streetNumber),
      addressComplement: _emptyToNull(addressComplement),
      neighborhood: _emptyToNull(neighborhood),
      city: _emptyToNull(city),
      stateCode: _emptyToNull(stateCode),
      country: (_emptyToNull(country) ?? 'BR').toUpperCase(),
      status: status,
      billingType: billingType,
      hasDanielParticipation: hasDanielParticipation,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    _clients = [client, ..._clients];
    await _repository.cacheAll(_clients);
    notifyListeners();

    try {
      final saved = await _repository.upsert(client);
      _replace(saved);
      await _repository.cacheAll(_clients);
      _errorMessage = null;
    } catch (_) {
      _errorMessage =
          'Cliente salvo localmente. A sincronizacao com Supabase falhou.';
    } finally {
      notifyListeners();
    }
  }

  void _replace(ClientModel updated) {
    _clients = _clients
        .map((client) => client.id == updated.id ? updated : client)
        .toList(growable: false);
  }

  static String? _emptyToNull(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
